#!/bin/sh

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
  printf "${YELLOW}\nUsage: $0 [-u user] [-o output_dir] host${RESET}\n"
  echo "Usae env variable SSH_OPTIONS if needed (e.g., export SSH_OPTIONS="-i $HOME/.ssh/google_compute_engine")\n\n"
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
  printf "${RED}Error: host argument is required.${RESET}\n"
  usage
fi

REMOTE_HOST="$1"

# Ensure local backup directory exists
mkdir -p "$LOCAL_BACKUP_DIR"

echo "Starting backup process..."

# Execute remote commands via a single SSH call, stream the tarball to local file
ssh $REMOTE_HOST -t 'sh -s' <<'ENDSSH' >"$LOCAL_BACKUP_DIR/db_backups_${DATE}.tar.gz"
set -e

export PGPASSWORD='${PGPASSWORD}'
export PGPASSWORD=r6grgfm
echo $PGPASSWORD
DATE=$(date +%Y%m%d)
REMOTE_TMP_DIR="/tmp/db_backups_${DATE}_$$"

echo "Creating temporary directory: $REMOTE_TMP_DIR"
mkdir -p "$REMOTE_TMP_DIR"

echo "Retrieving database list..."
DBLIST=$(psql -U postgres -Atc "SELECT datname FROM pg_database WHERE datistemplate = false AND datname NOT IN ('postgres', 'template0', 'template1');")

for DB in $DBLIST; do
    echo "Backing up database: $DB"
    pg_dump -U postgres -F c -b -v -f "$REMOTE_TMP_DIR/${DB}-${DATE}.sql" "$DB"
done

# Optional: Include the 'postgres' database
# echo "Backing up database: postgres"
# pg_dump -U postgres -F c -b -v -f "$REMOTE_TMP_DIR/postgres-${DATE}.sql" "postgres"

echo "Creating tarball of backup files..."
tar -C "$REMOTE_TMP_DIR" -czf - .

echo "Cleaning up temporary files..."
rm -rf "$REMOTE_TMP_DIR"
ENDSSH

if [ $? -eq 0 ]; then
  echo "Backup completed successfully!"
  echo "Backup file located at: $LOCAL_BACKUP_DIR/db_backups_${DATE}.tar.gz"
else
  echo "Backup failed."
  exit 1
fi
