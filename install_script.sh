#!/bin/sh

# Default output format and quiet mode
OUTPUT_FORMAT="ansi"
QUIET="false"

# Parse command-line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --output-format=*)
            OUTPUT_FORMAT="${1#*=}"
            ;;
        --quiet)
            QUIET="true"
            ;;
        *)
            # Unknown option
            ;;
    esac
    shift
done

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
                *)
                    echo -e "$MESSAGE"
                    ;;
            esac
            ;;
        json)
            # Escape quotes and backslashes in message
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

# Function to check if an app is a service
is_service_app() {
    APP="$1"
    case " $SERVICES " in
        *" $APP "*) return 0 ;;
        *) return 1 ;;
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

# List of apps to install
APPS="nginx git erlang-runtime27-27.0"

# List of services to enable and start
SERVICES="nginx"

for APP in $APPS; do
    # Check if package is installed
    if pkg info "$APP" >/dev/null 2>&1; then
        output_message "not_needed" "$APP is already installed."
    else
        # Try to install the package
        if run_cmd doas pkg install -y "$APP"; then
            output_message "success" "$APP installed successfully."
        else
            output_message "error" "Failed to install $APP."
            continue
        fi
    fi

    # If app is a service, enable and start it
    if is_service_app "$APP"; then
        if run_cmd doas sysrc "${APP}_enable=YES"; then
            output_message "success" "$APP service enabled."
        else
            output_message "error" "Failed to enable $APP service."
        fi

        # Check if the service is already running
        run_cmd doas service "$APP" status
        SERVICE_STATUS=$?

        if [ $SERVICE_STATUS -eq 0 ]; then
            output_message "not_needed" "$APP service is already running."
        else
            # Attempt to start the service
            if run_cmd doas service "$APP" start; then
                output_message "success" "$APP service started."
            else
                output_message "error" "Failed to start $APP service."
            fi
        fi
    fi
done

# Output JSON_MESSAGES if in JSON format
if [ "$OUTPUT_FORMAT" = "json" ]; then
    echo -e "[$JSON_MESSAGES]"
fi
