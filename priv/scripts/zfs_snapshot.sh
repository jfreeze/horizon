#!/bin/sh

# Defaults
USER=$(whoami)
HOST=""
NOW=$(date +"%Y%m%d%H%M%S")
SNAPSHOT_PREFIX="zroot/var/db/postgres"
DAILY_PREFIX="daily"
ROLLING_PREFIX="rolling"
RETENTION_DAYS=14
ROLLING_COUNT=24

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

# SSH and ZFS commands with additional SSH options to suppress MOTD
SSH_CMD="ssh -T ${USER}@${HOST} sh -s"
ZFS_CMD="doas zfs"

# Get the latest snapshot on the remote host
get_latest_remote_snapshot() {
  ssh "${USER}@${HOST}" "${ZFS_CMD} list -t snapshot -o name -s creation | grep ${SNAPSHOT_PREFIX}@$ROLLING_PREFIX | tail -1"
}

# Get the latest snapshot on the local (controlling) host
get_latest_local_snapshot() {
  doas zfs list -t snapshot -o name -s creation | grep ${SNAPSHOT_PREFIX}@$ROLLING_PREFIX | tail -1
}

# Send the snapshot to the controlling host
send_snapshot_to_host() {
  local snapshot_name=$1
  local previous_snapshot=$2

  if [ -z "$previous_snapshot" ]; then
    echo "Sending full snapshot $snapshot_name to controlling host..."
    echo "ssh ${USER}@${HOST} doas zfs send -vcR ${snapshot_name} | doas zfs receive -F ${SNAPSHOT_PREFIX}"
    ssh "${USER}@${HOST}" "doas zfs send -vcR ${snapshot_name}" | doas zfs receive -F ${SNAPSHOT_PREFIX}
  else
    echo "Sending incremental snapshot from $previous_snapshot to $snapshot_name..."
    echo "ssh ${USER}@${HOST} doas zfs send -vcRI ${previous_snapshot} ${snapshot_name} | doas zfs receive -F ${SNAPSHOT_PREFIX}"
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
echo "PostgreSQL backup and ZFS snapshot completed."

snapshot_name="${SNAPSHOT_PREFIX}@$ROLLING_PREFIX-$NOW"

# Logging to debug
echo "Latest remote snapshot: $latest_rolling_snapshot_remote"
echo "Latest local snapshot: $latest_rolling_snapshot_local"

# Determine whether to send full or incremental snapshot
if [ "$latest_rolling_snapshot_remote" = "$latest_rolling_snapshot_local" ] && [ -n "$latest_rolling_snapshot_local" ]; then
  # Send incremental snapshot if the latest snapshots match and there is a snapshot
  send_snapshot_to_host "$snapshot_name" "$latest_rolling_snapshot_local"
else
  # Send full snapshot if no matching snapshot is found or if no previous snapshots exist
  echo "No common snapshot found, or no previous snapshots. Sending full snapshot."
  send_snapshot_to_host "$snapshot_name" ""
fi

# Cleanup old rolling snapshots if more than 24 exist
cleanup_old_rolling_snapshots() {
  echo "Cleaning up old rolling snapshots..."
  snapshot_count=$(ssh "${USER}@${HOST}" "doas zfs list -t snapshot -o name | grep ${SNAPSHOT_PREFIX}@${ROLLING_PREFIX} | wc -l")

  if [ "$snapshot_count" -gt "$ROLLING_COUNT" ]; then
    echo "Cleaning up old rolling snapshots..."
    ssh "${USER}@${HOST}" "${ZFS_CMD} list -t snapshot -o name -s creation | grep ${SNAPSHOT_PREFIX}@${ROLLING_PREFIX} | head -n -$ROLLING_COUNT | xargs -I {} doas zfs destroy {}"
  else
    echo "Not enough snapshots for cleanup. Current count: $snapshot_count, required: $ROLLING_COUNT"
  fi
}

# Clean up old rolling snapshots
cleanup_old_rolling_snapshots

# Handle Daily Snapshots (at midnight only)
if [ "$(date +%H%M)" = "0000" ]; then
  # It's midnight, take a daily snapshot and clean up old daily snapshots
  take_daily_snapshot
  cleanup_old_daily_snapshots
fi

echo "Snapshot process completed."
