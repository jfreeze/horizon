#!/bin/sh

# Set the date format for the backup filenames
DATE=$(date +%Y%m%d)

# Default values
PGPORT="5432"
PGUSER="postgres"
LOCAL_BACKUP_DIR=$(pwd)
DATE=$(date +%Y%m%d)

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'å

# Function to display usage
usage() {
  echo "Usage: $0 [-p port] [-U user] [-o output_dir] host"
  echo
  echo "Options:"
  echo "  -p port         PostgreSQL server port (default: 5432)"
  echo "  -U user         PostgreSQL user (default: postgres)"
  echo "  -o output_dir   Local directory to store backups (default: current directory)"
  exit 1
}

# Parse options
while getopts ":h:p:U:o:" opt; do
  case $opt in
  p)
    PGPORT=$OPTARG
    ;;
  U)
    PGUSER=$OPTARG
    ;;
  o)
    LOCAL_BACKUP_DIR=$OPTARG
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    usage
    ;;
  :)
    echo "Option -$OPTARG requires an argument." >&2
    usage
    ;;
  esac
done

shift $((OPTIND - 1))

# Check for required positional argument 'host'
if [ $# -lt 1 ]; then
  printf "${RED}Error: host argument is required.${RESET}\n"
  usage
fi

PGHOST="$1"

# Ensure local backup directory exists
mkdir -p "$LOCAL_BACKUP_DIR"

echo "Starting backup process..."

# Prompt for PGPASSWORD if not set
if [ -z "$PGPASSWORD" ]; then
  printf "${YELLOW}Enter PostgreSQL password for user '$PGUSER': ${RESET}"
  stty -echo
  read PGPASSWORD
  stty echo
  echo
fi

export PGPASSWORD

# Retrieve database list
echo "Retrieving database list from $PGHOST:$PGPORT..."
DBLIST=$(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -Atc "SELECT datname FROM pg_database WHERE datistemplate = false AND datname NOT IN ('postgres');")

if [ -z "$DBLIST" ]; then
  echo "No databases found to back up."
  exit 1
fi

# Create a temporary directory for backups
TMP_BACKUP_DIR="$LOCAL_BACKUP_DIR/db_backups_${DATE}_$$"
mkdir -p "$TMP_BACKUP_DIR"

# Backup each database
for DB in $DBLIST; do
  echo "Backing up database: $DB"
  pg_dump -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -F c -b -v -f "$TMP_BACKUP_DIR/${DB}-${DATE}.backup" "$DB"
  if [ $? -ne 0 ]; then
    echo "Error backing up database: $DB"
    exit 1
  fi
done

# Create a tarball of the backups
echo "Creating tarball of backup files..."
tar -C "$TMP_BACKUP_DIR" -czf "$LOCAL_BACKUP_DIR/db_backups_${DATE}.tar.gz" .
if [ $? -eq 0 ]; then
  printf "${GREEN}Backup completed successfully!${RESET}\n"
  printf "${GREEN}Backup file located at: $LOCAL_BACKUP_DIR/db_backups_${DATE}.tar.gz${RESET}\n"
else
  echo "${RED}Failed to create tarball.${RESET}\n"
  exit 1
fi

# Clean up temporary backup files
rm -rf "$TMP_BACKUP_DIR"

# Unset PGPASSWORD
unset PGPASSWORD
