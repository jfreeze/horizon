#!/bin/sh

#
# Parses a configuration file and generate arguments for the installation script
#
# Usage: bsd_install_args.sh <config_file>
#

CONFIG_FILE="$1"

if [ -z "$CONFIG_FILE" ]; then
  echo "Usage: installer.sh <config_file>"
  exit 1
fi

INSTALL_SCRIPT="./install_script.sh"

ARGS=""

while IFS= read -r line; do
  # Remove comments starting with '#' and trim whitespace
  line="${line%%\#*}"    # Remove comments
  line="$(echo "$line")" # Remove leading and trailing whitespace

  # Skip empty lines
  if [ -z "$line" ]; then
    continue
  fi

  # Parse the line
  case "$line" in
  path:*)
    PATH_VAL="${line#path:}"
    ARGS="$ARGS --path $PATH_VAL"
    ;;
  pkg:*)
    APP="${line#pkg:}"
    ARGS="$ARGS --pkg $APP"
    ;;
  service:*)
    SERVICE="${line#service:}"
    ARGS="$ARGS --service $SERVICE"
    ;;
  elixir:*)
    ELIXIR_VERSION="${line#elixir:}"
    ARGS="$ARGS --elixir $ELIXIR_VERSION"
    ;;
  postgres)
    ARGS="$ARGS --postgres"
    ;;
  *)
    echo "Unknown config line: $line"
    exit 1
    ;;
  esac
done <"$CONFIG_FILE"

# Call the installer script with the parsed arguments
echo $ARGS
#sh "$INSTALL_SCRIPT" $ARGS
