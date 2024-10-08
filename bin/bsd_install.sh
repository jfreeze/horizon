#!/bin/sh

export SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/horizon_helpers.sh"

# Usage
usage() {
  echo "\n"
  echo "${GREEN}Usage: $0 [-u user] [--json] machine config_file${NC}"
  echo "  -u user      Specify the remote user (optional, defaults to current user)"
  echo "  --json       Output in JSON format (optional)"
  echo "  host         Target host's IP address or hostname"
  echo "  config_file  Path to the configuration file"
  echo "\n"
  exit 1
}

# Initialize variables
REMOTE_USER=$(whoami) # Default to current user
OUTPUT_FORMAT=""

# Parse options
while [ $# -gt 0 ]; do
  case "$1" in
  -u)
    shift
    REMOTE_USER="$1"
    ;;
  --json)
    OUTPUT_FORMAT="--output-format=json"
    ;;
  --)
    shift
    break
    ;;
  -*)
    usage
    ;;
  *)
    break
    ;;
  esac
  shift
done

# Check for required positional arguments
if [ $# -ne 2 ]; then
  usage
fi

# Assign positional arguments after options have been shifted
HOST="$1"
CONFIG_FILE="$2"

# Display parsed values
echo_info "Installing $CONFIG_FILE on $REMOTE_USER@$HOST"

# Check if configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo_error "Configuration file '$CONFIG_FILE' does not exist."
  exit 1
fi

# Path to the installation script
INSTALL_SCRIPT="${SCRIPT_DIR}/bsd_install_script.sh"

# Check if installation script exists
if [ ! -f "$INSTALL_SCRIPT" ]; then
  echo_error "Installation script '$INSTALL_SCRIPT' does not exist."
  exit 1
fi

# Generate installation arguments using install_args.sh
INSTALL_ARGS=$("${SCRIPT_DIR}/bsd_install_args.sh" "$CONFIG_FILE")

# Check if arguments were generated
if [ -z "$INSTALL_ARGS" ]; then
  echo_error "No installation arguments generated. Please check the configuration file."
  exit 1
fi

# Add output format if specified
if [ -n "$OUTPUT_FORMAT" ]; then
  INSTALL_ARGS="$INSTALL_ARGS $OUTPUT_FORMAT"
fi

# Display the arguments for verification (optional)
echo "Arguments to pass: $INSTALL_ARGS"

# Execute the installation script on the remote machine
# Using SSH with the specified user and machine
# The -- ensures that sh does not interpret any further options
# Properly quote the arguments to handle spaces or special characters
ssh "${REMOTE_USER}@${HOST}" "sh -s -- $INSTALL_ARGS" <"$INSTALL_SCRIPT"

# Alternatively, if you prefer piping:
# cat "$INSTALL_SCRIPT" | ssh "${REMOTE_USER}@${HOST}" "sh -s -- $INSTALL_ARGS"
