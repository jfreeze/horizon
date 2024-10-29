#!/bin/sh

# This script automates the process of taking and managing ZFS snapshots on a remote host,
# as well as sending them to a controlling host for backup. It handles both rolling and
# daily snapshots, sending incremental snapshots when possible and full snapshots otherwise.
# The script also manages the cleanup of old snapshots based on retention policies.
#
# Usage:
#   ./zfs_snapshot.sh [-u user] host
#
# Options:
#   -u user   Specify the SSH user to connect to the remote host. Defaults to the current user if not provided.
#   host      The remote host where PostgreSQL is running and ZFS snapshots will be managed.
#
# Functionality:
#   1. Takes a PostgreSQL backup on the remote host.
#   2. Creates a ZFS snapshot of the PostgreSQL database directory.
#   3. If a snapshot exists, it sends an incremental snapshot. Otherwise, it sends a full snapshot.
#   4. At midnight, the script takes a daily snapshot and sends it to the controlling host using
#      the same logic as the rolling snapshots (incremental vs full).
#   5. Cleans up old rolling snapshots to maintain a 24-hour rolling window (24 snapshots).
#   6. Cleans up old daily snapshots, keeping only the snapshots taken in the last 14 days (configurable).
#
# Crontab Setup:
#   To automate the script, add the following entries to your crontab (crontab -e):
#
#   # Rolling snapshots: Run every 30 minutes and daily at midnight
#   */30 * * * * /path/to/zfs_snapshot.sh -u <backup_user> <postgres_host> >> /path/to/zfs_snapshot.log 2>&1
#
# Configuration:
#   - SNAPSHOT_PREFIX: The ZFS dataset to snapshot (e.g., zroot/var/db/postgres).
#   - ROLLING_PREFIX:  Prefix for rolling snapshots (default: "rolling").
#   - DAILY_PREFIX:    Prefix for daily snapshots (default: "daily").
#   - RETENTION_DAYS:  Number of days to retain daily snapshots (default: 14 days).
#   - ROLLING_COUNT:   Number of rolling snapshots to retain (default: 48 snapshots).
#
# Example:
#   ./zfs_snapshot.sh -u backup_user 192.168.100.100
#   This will run the snapshot process on the remote host 192.168.100.100 using the SSH user 'backup_user'.
#
# Dependencies:
#   - ZFS must be installed and configured on both the remote and controlling hosts.
#   - PostgreSQL must be running on the remote host, with access to manage backups.
#   - The 'doas' command is used to execute ZFS and PostgreSQL commands with elevated privileges.
#
# Notes:
#   - Ensure that SSH access is properly configured between the controlling host and the remote host.
#   - The script expects the PostgreSQL instance to be running on the default port and socket.
#   - All snapshots are created with a timestamp-based naming convention for easy tracking.

# Defaults
USER=$(whoami)
HOST=""
NOW=$(date +"%Y%m%d%H%M%S")
SNAPSHOT_PREFIX="zroot/var/db/postgres"
DAILY_PREFIX="daily"
ROLLING_PREFIX="rolling"
RETENTION_DAYS=14
ROLLING_COUNT=48

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

# Parse command-line arguments
while getopts "u:" opt; do
  case $opt in
  u) USER="$OPTARG" ;;
  *) echo "Usage: $0 [-u user] host" && exit 1 ;;
  esac
done

# Shift to remaining non-option arguments (i.e., the host)
shift $((OPTIND - 1))

# Get the host argument (first remaining argument after options)
HOST="$1"
if [ -z "$HOST" ]; then
  echo "Host is required. Usage: $0 [-u user] host"
  exit 1
fi

# SSH and ZFS commands
SSH_CMD="ssh -T ${USER}@${HOST} sh -s"
ZFS_CMD="doas zfs"

# Get the latest snapshot on the remote host
get_latest_remote_snapshot() {
  ssh "${USER}@${HOST}" "${ZFS_CMD} list -t snapshot -o name -s creation | grep ${SNAPSHOT_PREFIX}@$ROLLING_PREFIX | sort -V | tail -1"
}

# Get the latest snapshot on the local (controlling) host
get_latest_local_snapshot() {
  doas zfs list -t snapshot -o name -s creation | grep ${SNAPSHOT_PREFIX}@$ROLLING_PREFIX | sort -V | tail -1
}

# Send the snapshot to the controlling host
send_snapshot_to_host() {
  local snapshot_name=$1
  local previous_snapshot=$2
  local prefix=$3

  if [ -z "$previous_snapshot" ]; then
    printf "${YELLOW}Sending full ${prefix} snapshot $snapshot_name to controlling host...${RESET}\n"
    ssh "${USER}@${HOST}" "doas zfs send -vcR ${snapshot_name}" | doas zfs receive -F ${SNAPSHOT_PREFIX}
    chown -R postgres:postgres /var/db/postgres
  else
    printf "${YELLOW}Sending incremental ${prefix} snapshot from $previous_snapshot to $snapshot_name...${RESET}\n"
    ssh "${USER}@${HOST}" "doas zfs send -vcRI ${previous_snapshot} ${snapshot_name}" | doas zfs receive -F ${SNAPSHOT_PREFIX}
  fi
}

# Main script execution

# Get the latest rolling snapshot from both the remote and local hosts
latest_rolling_snapshot_remote=$(get_latest_remote_snapshot)
latest_rolling_snapshot_local=$(get_latest_local_snapshot)

# Single SSH call for PostgreSQL backup and ZFS snapshot creation
echo "Running PostgreSQL backup and creating ZFS snapshot..."
${SSH_CMD} <<EOF
  doas -u postgres psql -c "SELECT pg_backup_start('$NOW');" 2>&1
  doas zfs snapshot ${SNAPSHOT_PREFIX}@$ROLLING_PREFIX-$NOW 2>&1
  doas -u postgres psql -q -c "SELECT pg_backup_stop();" 2>&1
EOF
printf "${GREEN}PostgreSQL backup and ZFS snapshot completed.${RESET}\n"

snapshot_name="${SNAPSHOT_PREFIX}@$ROLLING_PREFIX-$NOW"

# # Logging to debug
# printf "${YELLOW}Latest remote snapshot: $latest_rolling_snapshot_remote${RESET}\n"
# printf "${YELLOW}Latest local snapshot: $latest_rolling_snapshot_local${RESET}\n"
# printf "${YELLOW}New snapshot: $snapshot_name${RESET}\n"

# Determine whether to send full or incremental snapshot
if [ -n "$latest_rolling_snapshot_local" ]; then
  # Send incremental snapshot if the latest snapshots match and there is a snapshot
  send_snapshot_to_host "$snapshot_name" "$latest_rolling_snapshot_local" "$ROLLING_PREFIX"
else
  # Send full snapshot if no matching snapshot is found or if no previous snapshots exist
  echo "No common snapshot found, or no previous snapshots. Sending full snapshot."
  send_snapshot_to_host "$snapshot_name" "" "$ROLLING_PREFIX"
fi

# Take a daily snapshot
take_daily_snapshot() {
  printf "${YELLOW}Taking daily snapshot...${RESET}\n"
  ${SSH_CMD} <<EOF
    ${ZFS_CMD} snapshot ${SNAPSHOT_PREFIX}@$DAILY_PREFIX-$NOW
EOF
}

# Clean up old daily snapshots (older than RETENTION_DAYS)
cleanup_old_daily_snapshots() {
  printf "${YELLOW}Cleaning up old daily snapshots older than ${RETENTION_DAYS} days...${RESET}\n"
  ssh "${USER}@${HOST}" "${ZFS_CMD} list -t snapshot -o name -s creation | grep ${SNAPSHOT_PREFIX}@$DAILY_PREFIX | head -n -$RETENTION_DAYS | xargs -I {} doas zfs destroy {}"
}

# Cleanup old rolling snapshots if more than 24 exist
cleanup_old_rolling_snapshots() {
  printf "${YELLOW}Cleaning up old rolling snapshots...${RESET}\n"
  snapshot_count=$(ssh "${USER}@${HOST}" "doas zfs list -t snapshot -o name | grep ${SNAPSHOT_PREFIX}@${ROLLING_PREFIX} | wc -l")

  if [ "$snapshot_count" -gt "$ROLLING_COUNT" ]; then
    printf "${YELLOW}Cleaning up old rolling snapshots...${RESET}\n"
    ssh "${USER}@${HOST}" "${ZFS_CMD} list -t snapshot -o name -s creation | grep ${SNAPSHOT_PREFIX}@${ROLLING_PREFIX} | head -n -$ROLLING_COUNT | xargs -I {} doas zfs destroy {}"
  else
    echo "Not enough snapshots for cleanup. Current count: $snapshot_count, required: $ROLLING_COUNT"
  fi
}

# Clean up old rolling snapshots
cleanup_old_rolling_snapshots

# Handle Daily Snapshots (at midnight only)
if [ "$(date +%H%M)" = "0000" ]; then
  printf "${YELLOW}It's midnight! Taking daily snapshot...${RESET}\n"
  take_daily_snapshot

  # Get the latest daily snapshot from both the remote and local hosts
  latest_daily_snapshot_remote=$(get_latest_remote_snapshot "$DAILY_PREFIX")
  latest_daily_snapshot_local=$(get_latest_local_snapshot "$DAILY_PREFIX")

  # Determine whether to send full or incremental daily snapshot
  if [ -n "$latest_daily_snapshot_local" ]; then
    # Send incremental daily snapshot if the latest snapshot exists on the local host
    send_snapshot_to_host "${SNAPSHOT_PREFIX}@$DAILY_PREFIX-$NOW" "$latest_daily_snapshot_local" "$DAILY_PREFIX"
  else
    # Send full daily snapshot if no matching snapshot is found
    echo "No previous daily snapshot found. Sending full daily snapshot."
    send_snapshot_to_host "${SNAPSHOT_PREFIX}@$DAILY_PREFIX-$NOW" "" "$DAILY_PREFIX"
  fi

  cleanup_old_daily_snapshots
fi

printf "${GREEN}Snapshot process completed.${RESET}\n"