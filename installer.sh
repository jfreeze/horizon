#!/bin/sh

# Check if a configuration file is provided
CONFIG_FILE="$1"

if [ -z "$CONFIG_FILE" ]; then
  echo "Usage: installer.sh <config_file>"
  exit 1
fi

# Path to the installation script
INSTALL_SCRIPT="./install_script.sh"

# Generate installation arguments from the config file
INSTALL_ARGS=$(./installer_args.sh "$CONFIG_FILE")

# Check if arguments were generated
if [ -z "$INSTALL_ARGS" ]; then
  echo "No installation arguments generated. Exiting."
  exit 1
fi

# Execute the installation script on the remote machine with the generated arguments
cat "$INSTALL_SCRIPT" | ssj 176 "sh -s -- $INSTALL_ARGS"
