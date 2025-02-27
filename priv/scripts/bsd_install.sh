#!/bin/sh

# File autogenerated by mix horizon.init (source: bsd_install.sh.eex) - Horizon Version: 0.3.0

export SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/horizon_helpers.sh"

# Function to display usage
usage() {
  echo "\n"
  echo "${GREEN}Usage: $0 [--json] [--verbose] host config_file${NC}"
  echo "  --json       Output in JSON format (optional)"
  echo "  --verbose    Enable verbose output (optional)"
  echo "  host         [user@]remote_host"
  echo "  config_file  Path to the configuration file"
  echo "\n"
  echo "Horizon v0.3.0"
  echo "\n"
  exit 1
}

# Function to print error messages and exit
print_error() {
  echo "\033[0;31m[ERROR] $1\033[0m" >&2
  exit 1
}

# Initialize variables
OUTPUT_FORMAT=""
QUIET=""
VERBOSE=""

# Parse options
while [ $# -gt 0 ]; do
  case "$1" in
  --json)
    OUTPUT_FORMAT="--output-format=json"
    ;;
  --quiet)
    QUIET="--quiet"
    ;;
  --verbose)
    VERBOSE="--verbose"
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
echo "${GREEN}[INFO] Installing $CONFIG_FILE on ${HOST}${RESET}"

# Check if configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
  print_error "Configuration file '$CONFIG_FILE' does not exist."
fi

# Path to the installation script
INSTALL_SCRIPT="${SCRIPT_DIR}/bsd_install_script.sh"

# Check if installation script exists
if [ ! -f "$INSTALL_SCRIPT" ]; then
  print_error "Installation script '$INSTALL_SCRIPT' does not exist."
fi

# Generate installation arguments using install_args.sh
INSTALL_ARGS=$("${SCRIPT_DIR}/bsd_install_args.sh" "$CONFIG_FILE" 2>&1)
if echo "$INSTALL_ARGS" | grep -q "\[ERROR\]"; then
  print_error "$INSTALL_ARGS"
fi

# Check if arguments were generated
if [ -z "$INSTALL_ARGS" ]; then
  print_error "No installation arguments generated. Please check the configuration file."
fi

# Add output format if specified
if [ -n "$OUTPUT_FORMAT" ]; then
  INSTALL_ARGS="$INSTALL_ARGS $OUTPUT_FORMAT"
fi

# Add quiet mode if specified
if [ -n "$QUIET" ]; then
  INSTALL_ARGS="$INSTALL_ARGS $QUIET"
fi

# Debug: Print the generated INSTALL_ARGS
echo "\033[0;33m[DEBUG] Generated installation arguments: $INSTALL_ARGS\033[0m"

# Execute the installation script on the remote machine
# Using SSH with the specified user and machine
# The -- ensures that sh does not interpret any further options
# Properly quote the arguments to handle spaces or special characters
if ! ssh "${HOST}" "sh -s -- $INSTALL_ARGS $VERBOSE" <"$INSTALL_SCRIPT"; then
  print_error "Failed to execute the installation script on the remote machine: ${HOST}"
fi
