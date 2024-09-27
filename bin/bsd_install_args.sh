#!/bin/sh

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
  pkg:*)
    APP="${line#pkg:}"
    ARGS="$ARGS --pkg $APP"
    ;;
  elixir:*)
    ELIXIR_VERSION="${line#elixir:}"
    ARGS="$ARGS --elixir $ELIXIR_VERSION"
    ;;
  service:*)
    SERVICE="${line#service:}"
    ARGS="$ARGS --service $SERVICE"
    ;;
  path:*)
    PATH_VAL="${line#path:}"
    ARGS="$ARGS --path $PATH_VAL"
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