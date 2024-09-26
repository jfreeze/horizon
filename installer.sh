#!/bin/sh

# Function to display usage
usage() {
  echo "Usage: $0 [-u user] machine config_file"
  echo "  -u user      Specify the remote user (optional, defaults to current user)"
  echo "  machine      Target machine's IP address or hostname"
  echo "  config_file  Path to the configuration file"
  exit 1
}

# Initialize variables
REMOTE_USER=$(whoami) # Default to current user
MACHINE=""
CONFIG_FILE=""

# Parse options
while getopts "u:" opt; do
  case "$opt" in
  u)
    REMOTE_USER="$OPTARG"
    ;;
  *)
    usage
    ;;
  esac
done

# Shift off the options and optional --
shift $((OPTIND - 1))

# Check for required positional arguments
if [ $# -ne 2 ]; then
  usage
fi

MACHINE="$1"
CONFIG_FILE="$2"

# Check if configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Configuration file '$CONFIG_FILE' does not exist."
  exit 1
fi

# Path to the installation script
INSTALL_SCRIPT="./install_script.sh"

# Check if installation script exists
if [ ! -f "$INSTALL_SCRIPT" ]; then
  echo "Error: Installation script '$INSTALL_SCRIPT' does not exist."
  exit 1
fi

# Generate installation arguments using install_args.sh
INSTALL_ARGS=$(./install_args.sh "$CONFIG_FILE")

# Check if arguments were generated
if [ -z "$INSTALL_ARGS" ]; then
  echo "Error: No installation arguments generated. Please check the configuration file."
  exit 1
fi

# Display the arguments for verification (optional)
echo "Arguments to pass: $INSTALL_ARGS"

# Execute the installation script on the remote machine
# Using SSH with the specified user and machine
# The -- ensures that sh does not interpret any further options
# Properly quote the arguments to handle spaces or special characters
ssh "${REMOTE_USER}@${MACHINE}" "sh -s -- $INSTALL_ARGS" <"$INSTALL_SCRIPT"

# Alternatively, if you prefer piping:
# cat "$INSTALL_SCRIPT" | ssh "${REMOTE_USER}@${MACHINE}" "sh -s -- $INSTALL_ARGS"
