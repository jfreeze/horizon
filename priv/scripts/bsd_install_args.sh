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
  dot-path:*)
    DPATH_VAL="${line#dot-path:}"
    ARGS="$ARGS --dot-path $DPATH_VAL"
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
  postgres\.init-zfs)
    ARGS="$ARGS --postgres-init-zfs"
    ;;
  postgres\.init)
    ARGS="$ARGS --postgres-init"
    ;;
  postgres\.db:*)
    DB_INFO="${line#postgres.db:}"
    ENCODING_TYPE="${DB_INFO%%:*}"
    DB_NAME="${DB_INFO#*:}"

    # Extract encoding options if provided
    case "$ENCODING_TYPE" in
    c_mixed_utf8)
      ARGS="$ARGS --postgres-db-c_mixed_utf8 $DB_NAME"
      ;;
    c_utf8_full)
      ARGS="$ARGS --postgres-db-c_utf8_full $DB_NAME"
      ;;
    us_utf8_full)
      ARGS="$ARGS --postgres-db-us_utf8_full $DB_NAME"
      ;;
    *)
      # No specific encoding abbreviation is provided, use default flag
      ARGS="$ARGS --postgres-db $DB_NAME"
      ;;
    esac
    ;;
  *)
    echo "Unknown config line: $line"
    exit 1
    ;;
  esac
done <"$CONFIG_FILE"

echo $ARGS
# Call the installer script with the parsed arguments
#sh "$INSTALL_SCRIPT" $ARGS
