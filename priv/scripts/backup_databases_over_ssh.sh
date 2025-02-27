#!/bin/sh
# Generated with Horizon Version: 0.3.0

# Default values
LOCAL_BACKUP_DIR=$(pwd)
DATE=$(date +%Y%m%d)

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

# Function to display usage
usage() {
  echo "Usage: $0 [-o output_dir] [user@]host (Horizon v0.3.0)"
  exit 1
}

# Parse options
while getopts ":o:" opt; do
  case $opt in
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
  echo "Error: host argument is required."
  usage
fi

REMOTE_HOST="$1"

# Ensure local backup directory exists
mkdir -p "$LOCAL_BACKUP_DIR"

echo "Starting backup process..."

# Prompt for PGPASSWORD if not set
if [ -z "$PGPASSWORD" ]; then
  printf "${YELLOW}Enter PostgreSQL password for user 'postgres': ${RESET}"
  stty -echo
  read PGPASSWORD
  stty echo
  echo
fi

# Execute remote commands via a single SSH call, stream the tarball to local file
ssh "$REMOTE_HOST" 'sh -s' >"$LOCAL_BACKUP_DIR/db_backups_${DATE}.tar.gz" <<ENDSSH
set -e

export PGPASSWORD='${PGPASSWORD}'

DATE=\$(date +%Y%m%d)
REMOTE_TMP_DIR="/tmp/db_backups_\${DATE}_\$\$"

echo "Creating temporary directory: \$REMOTE_TMP_DIR" >&2
mkdir -p "\$REMOTE_TMP_DIR"

echo "Retrieving database list..." >&2
DBLIST=\$(psql -h localhost -U postgres -Atc "SELECT datname FROM pg_database WHERE datistemplate = false AND datname NOT IN ('postgres', 'template0', 'template1');")

for DB in \$DBLIST; do
    echo "Backing up database: \$DB" >&2
    pg_dump -h localhost -U postgres -F c -b -f "\$REMOTE_TMP_DIR/\${DB}-\${DATE}.backup" "\$DB"
done

# Optional: Include the 'postgres' database
# echo "Backing up database: postgres"
# pg_dump -h localhost -U postgres -F c -b -f "\$REMOTE_TMP_DIR/postgres-\${DATE}.backup" "postgres"

echo "Creating tarball of backup files..." >&2
tar -C "\$REMOTE_TMP_DIR" -czf - .

echo "Cleaning up temporary files..." >&2
rm -rf "\$REMOTE_TMP_DIR"
ENDSSH

if [ $? -eq 0 ]; then
  printf "${GREEN}Backup completed successfully!${RESET}\n"
  echo "${GREEN}Backup file located at: $LOCAL_BACKUP_DIR/db_backups_${DATE}.tar.gz${RESET}\n"
else
  echo "${RED}Backup failed.${RESET}\n"
  exit 1
fi
