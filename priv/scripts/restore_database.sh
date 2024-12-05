#!/bin/sh

# Default values
PGPORT="5432"
PGUSER="postgres"
NO_OWNER="false"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

# Function to display usage
usage() {
  echo "Usage: $0 [-p port] [-U user] [-d database] [--no-owner] backup_file host"
  echo
  echo "Options:"
  echo "  -p port         PostgreSQL server port (default: 5432)"
  echo "  -U user         PostgreSQL user (default: postgres)"
  echo "  -d database     Database name to restore into"
  echo "  -n              Do not set ownership of objects to original owner"
  echo
  echo "Arguments:"
  echo "  backup_file     Path to the backup file (required)"
  echo "  host            PostgreSQL server host (required)"
  exit 1
}

# Parse options
while getopts ":p:U:d:n" opt; do
  case $opt in
  p)
    PGPORT=$OPTARG
    ;;
  U)
    PGUSER=$OPTARG
    ;;
  d)
    DATABASE=$OPTARG
    ;;
  n)
    NO_OWNER="true"
    ;;
  \?)
    printf "${RED}Invalid option: -$OPTARG${RESET}\n" >&2
    usage
    ;;
  :)
    printf "${YELLOW}Option -$OPTARG requires an argument.${RESET}\n" >&2
    usage
    ;;
  esac
done

shift $((OPTIND - 1))

# Check for required positional arguments
if [ $# -lt 2 ]; then
  printf "${RED}Error: backup_file and host arguments are required.${RESET}\n"
  usage
fi

BACKUP_FILE="$1"
PGHOST="$2"

# Ensure the backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
  printf "${RED}Error: Backup file '$BACKUP_FILE' does not exist.${RESET}\n"
  exit 1
fi

# Prompt for PGPASSWORD if not set
if [ -z "$PGPASSWORD" ]; then
  printf "${YELLOW}Enter PostgreSQL password for user '$PGUSER': ${RESET}"
  stty -echo
  read PGPASSWORD
  stty echo
  echo
fi

export PGPASSWORD

# Function to extract the database name from the backup file name
extract_db_name() {
  local filename
  filename=$(basename "$1")
  # Remove date suffix and extension
  db_name=$(echo "$filename" | sed -E 's/-[0-9]{8}\.(backup|sql)$//; s/\.(backup|sql)$//')
  echo "$db_name"
}

# Determine the database name
if [ -z "$DATABASE" ]; then
  DATABASE=$(extract_db_name "$BACKUP_FILE")
  if [ -z "$DATABASE" ]; then
    printf "${RED}Error: Unable to derive database name from backup file name. Please specify the database name using -d.${RESET}\n"
    exit 1
  fi
  printf "${YELLOW}Using database name '${DATABASE}' derived from backup file name.${RESET}\n"
else
  printf "${YELLOW}Using specified database name '${DATABASE}'.${RESET}\n"
fi

# Create the database if it doesn't exist
echo "Creating database '$DATABASE' if it does not exist..."
createdb -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" "$DATABASE" 2>/dev/null

if [ $? -ne 0 ]; then
  echo "Database '$DATABASE' may already exist or there may be a permission issue."
  echo "Proceeding with the restore..."
fi

if [ "$NO_OWNER" = "true" ]; then
  PG_RESTORE_CMD="pg_restore -h \"$PGHOST\" -p \"$PGPORT\" -U \"$PGUSER\" -d \"$DATABASE\" --no-owner -v \"$BACKUP_FILE\""
else
  PG_RESTORE_CMD="pg_restore -h \"$PGHOST\" -p \"$PGPORT\" -U \"$PGUSER\" -d \"$DATABASE\" -v \"$BACKUP_FILE\""
fi
# Other options
# --schema-only
# --datda-only

# Restore the database
echo "Restoring database '$DATABASE' from backup file '$BACKUP_FILE'..."
echo " cmd: $PG_RESTORE_CMD"

eval $PG_RESTORE_CMD

if [ $? -eq 0 ]; then
  printf "${GREEN}Database '$DATABASE' restored successfully!${RESET}\n"
else
  printf "${RED}Failed to restore database '$DATABASE'.${RESET}\n"
  exit 1
fi

# Unset PGPASSWORD
unset PGPASSWORD
