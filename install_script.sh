#!/bin/sh

# Default output format and quiet mode
OUTPUT_FORMAT="ansi"
QUIET="false"
ELIXIR_VERSION=""
COMMANDS="" # Use a string to store commands

# Parse command-line arguments
while [ $# -gt 0 ]; do
    case "$1" in
    --output-format=*)
        OUTPUT_FORMAT="${1#*=}"
        ;;
    --quiet)
        QUIET="true"
        ;;
    --pkg)
        shift
        if [ -n "$1" ]; then
            COMMANDS="$COMMANDS pkg:$1"
        else
            echo "Error: --pkg requires an argument"
            exit 1
        fi
        ;;
    --service)
        shift
        if [ -n "$1" ]; then
            COMMANDS="$COMMANDS service:$1"
        else
            echo "Error: --service requires an argument"
            exit 1
        fi
        ;;
    --elixir)
        shift
        if [ -n "$1" ]; then
            ELIXIR_VERSION="$1"
            COMMANDS="$COMMANDS elixir"
        else
            echo "Error: --elixir requires a version argument"
            exit 1
        fi
        ;;
    --path)
        shift
        if [ -n "$1" ]; then
            CUSTOM_PATHS="$1:$CUSTOM_PATHS"
        else
            echo "Error: --path requires an argument"
            exit 1
        fi
        ;;
    *)
        # Unknown option
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
    shift
done

# Update PATH with custom paths
if [ -n "$CUSTOM_PATHS" ]; then
    PATH="$CUSTOM_PATHS$PATH"
    export PATH
fi

# Define colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Initialize JSON_MESSAGES
JSON_MESSAGES=""

# Function to output messages
output_message() {
    STATUS="$1"
    MESSAGE="$2"
    case "$OUTPUT_FORMAT" in
    ansi)
        case "$STATUS" in
        success)
            echo -e "${GREEN}${MESSAGE}${NC}"
            ;;
        error)
            echo -e "${RED}${MESSAGE}${NC}"
            ;;
        not_needed)
            echo -e "${YELLOW}${MESSAGE}${NC}"
            ;;
        info)
            echo -e "$MESSAGE"
            ;;
        *)
            echo -e "$MESSAGE"
            ;;
        esac
        ;;
    json)
        # Escape quotes and backslashes in message
        # ESCAPED_MESSAGE=$(printf '%s' "$MESSAGE" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
        ESCAPED_MESSAGE=$(echo -e "$MESSAGE" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
        # Append JSON object to JSON_MESSAGES
        if [ -z "$JSON_MESSAGES" ]; then
            JSON_MESSAGES="{\"status\":\"$STATUS\",\"message\":\"$ESCAPED_MESSAGE\"}"
        else
            JSON_MESSAGES="$JSON_MESSAGES,{\"status\":\"$STATUS\",\"message\":\"$ESCAPED_MESSAGE\"}"
        fi
        ;;
    *)
        echo -e "$MESSAGE"
        ;;
    esac
}

# Function to run commands with optional quiet mode
run_cmd() {
    if [ "$QUIET" = "true" ]; then
        "$@" >/dev/null 2>&1
    else
        "$@"
    fi
    return $?
}

# Function to check if Elixir is installed
is_elixir_installed() {
    if command -v elixir >/dev/null 2>&1; then
        INSTALLED_VERSION=$(elixir --version | grep 'Elixir' | awk '{print $2}')
        if [ "$INSTALLED_VERSION" = "$ELIXIR_VERSION" ]; then
            return 0 # Elixir is installed and version matches
        else
            return 1 # Elixir is installed but version differs
        fi
    else
        return 1 # Elixir is not installed
    fi
}

# Function to install Elixir
install_elixir() {
    output_message "info" "Installing Elixir v$ELIXIR_VERSION..."
    WORKDIR=${WORKDIR:-$(mktemp -d -t elixir)}
    if [ ! -d "$WORKDIR" ]; then
        if ! run_cmd doas mkdir -p "$WORKDIR"; then
            output_message "error" "Failed to create directory $WORKDIR."
            return 1
        fi
    fi
    cd "$WORKDIR" || {
        output_message "error" "Failed to enter directory $WORKDIR."
        return 1
    }

    # Clone the Elixir repository
    if [ ! -d "elixir" ]; then
        if ! run_cmd git clone https://github.com/elixir-lang/elixir.git; then
            output_message "error" "Failed to clone Elixir repository."
            return 1
        fi
    else
        output_message "info" "Elixir repository already cloned."
    fi

    cd elixir || {
        output_message "error" "Failed to enter elixir directory."
        return 1
    }

    # Fetch tags and checkout the desired version
    if ! run_cmd git fetch --tags && run_cmd git checkout "v$ELIXIR_VERSION"; then
        output_message "error" "Failed to checkout Elixir version v$ELIXIR_VERSION."
        cd ..
        return 1
    fi

    # Compile Elixir
    if ! run_cmd gmake; then
        output_message "error" "Failed to build Elixir."
        cd ..
        return 1
    fi

    # Install Elixir
    if ! run_cmd doas gmake install; then
        output_message "error" "Failed to install Elixir."
        cd ..
        return 1
    fi

    cd ..
    output_message "success" "Elixir v$ELIXIR_VERSION installed successfully."
    return 0
}

# Process commands in the order they were provided
for CMD in $COMMANDS; do
    case "$CMD" in
    pkg:*)
        APP="${CMD#pkg:}"
        echo "APP: $APP"
        # Check if package is installed
        if pkg info "$APP" >/dev/null 2>&1; then
            output_message "not_needed" "$APP is already installed."
        else
            # Try to install the package
            if run_cmd doas pkg install -y "$APP"; then
                output_message "success" "$APP installed successfully."
            else
                output_message "error" "Failed to install $APP."
                exit 1
            fi
        fi
        ;;
    service:*)
        SERVICE="${CMD#service:}"
        # Enable and start the service
        if run_cmd doas sysrc "${SERVICE}_enable=YES"; then
            output_message "success" "$SERVICE service enabled."
        else
            output_message "error" "Failed to enable $SERVICE service."
        fi

        # Check if the service is already running
        run_cmd doas service "$SERVICE" status
        SERVICE_STATUS=$?

        if [ $SERVICE_STATUS -eq 0 ]; then
            output_message "not_needed" "$SERVICE service is already running."
        else
            # Attempt to start the service
            if run_cmd doas service "$SERVICE" start; then
                output_message "success" "$SERVICE service started."
            else
                output_message "error" "Failed to start $SERVICE service."
            fi
        fi
        ;;
    elixir)
        # Handle Elixir installation
        if [ -z "$ELIXIR_VERSION" ]; then
            output_message "error" "--elixir option requires a version."
            exit 1
        fi
        if is_elixir_installed; then
            output_message "not_needed" "Elixir v$ELIXIR_VERSION is already installed."
        else
            if install_elixir; then
                output_message "success" "Elixir v$ELIXIR_VERSION installed successfully."
            else
                output_message "error" "Failed to install Elixir v$ELIXIR_VERSION."
                exit 1
            fi
        fi
        ;;
    *)
        output_message "error" "Unknown command: $CMD"
        exit 1
        ;;
    esac
done

# Output JSON_MESSAGES if in JSON format
if [ "$OUTPUT_FORMAT" = "json" ]; then
    echo -e "[${JSON_MESSAGES}]"
fi
