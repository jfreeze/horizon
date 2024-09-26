#!/bin/sh

# Default output format
if [ -t 1 ]; then
    OUTPUT_FORMAT="ansi"
else
    OUTPUT_FORMAT="json"
fi

# Parse command-line arguments
for arg in "$@"; do
    case $arg in
        --output-format=*)
        OUTPUT_FORMAT="${arg#*=}"
        shift
        ;;
        *)
        # Unknown option
        ;;
    esac
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
                    echo "${GREEN}${MESSAGE}${NC}"
                    ;;
                error)
                    echo "${RED}${MESSAGE}${NC}"
                    ;;
                not_needed)
                    echo "${YELLOW}${MESSAGE}${NC}"
                    ;;
                *)
                    echo "$MESSAGE"
                    ;;
            esac
            ;;
        json)
            # Escape quotes and backslashes in message
            ESCAPED_MESSAGE=$(printf '%s' "$MESSAGE" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
            # Append JSON object to JSON_MESSAGES
            if [ -z "$JSON_MESSAGES" ]; then
                JSON_MESSAGES="{\"status\":\"$STATUS\",\"message\":\"$ESCAPED_MESSAGE\"}"
            else
                JSON_MESSAGES="$JSON_MESSAGES,{\"status\":\"$STATUS\",\"message\":\"$ESCAPED_MESSAGE\"}"
            fi
            ;;
        *)
            echo "$MESSAGE"
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

# List of apps to install
APPS="nginx"

# List of services to enable and start
SERVICES="nginx"

for APP in $APPS; do
    # Check if package is installed
    if pkg info "$APP" >/dev/null 2>&1; then
        output_message "not_needed" "$APP is already installed."
    else
        # Try to install the package
        if doas pkg install -y "$APP" >/dev/null 2>&1; then
            output_message "success" "$APP installed successfully."
        else
            output_message "error" "Failed to install $APP."
            continue
        fi
    fi

    # If app is a service, enable and start it
    if is_service_app "$APP"; then
        if doas sysrc "${APP}_enable=YES" >/dev/null 2>&1; then
            output_message "success" "$APP service enabled."
        else
            output_message "error" "Failed to enable $APP service."
        fi

        if doas service "$APP" start >/dev/null 2>&1; then
            output_message "success" "$APP service started."
        else
            output_message "error" "Failed to start $APP service."
        fi
    fi
done

# Output JSON_MESSAGES if in JSON format
if [ "$OUTPUT_FORMAT" = "json" ]; then
    echo "[$JSON_MESSAGES]"
fi

