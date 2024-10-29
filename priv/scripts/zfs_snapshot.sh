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
SSH_CMD="ssh -T ${USER}@${HOST} 'sh -s'"
ZFS_CMD="doas zfs"

# Get the list of existing rolling snapshots
get_latest_snapshot() {
  ${SSH_CMD} <<EOF
    ${ZFS_CMD} list -t snapshot -o name -s creation | grep $SNAPSHOT_PREFIX@$1
EOF
}

# Send the snapshot to the controlling host
send_snapshot_to_host() {
  local snapshot_name=$1
  local previous_snapshot=$2

  if [ -z "$previous_snapshot" ]; then
    echo "Sending full snapshot $snapshot_name to controlling host..."
    ${SSH_CMD} <<EOF
          doas zfs send -vcR $snapshot_name | ssh ${USER}@$(hostname) "doas zfs receive -F $SNAPSHOT_PREFIX"
EOF
  else
    echo "Sending incremental snapshot from $previous_snapshot to $snapshot_name..."
    ${SSH_CMD} <<EOF
          doas zfs send -vcRI $previous_snapshot $snapshot_name | ssh ${USER}@$(hostname) "doas zfs receive -F $SNAPSHOT_PREFIX"
EOF
  fi
}

# Main script execution
latest_rolling_snapshot=$(get_latest_snapshot "$ROLLING_PREFIX")

# Single SSH call for PostgreSQL backup and ZFS snapshot creation
echo "Running PostgreSQL backup and creating ZFS snapshot..."
${SSH_CMD} <<EOF
  doas -u postgres psql -c "SELECT pg_backup_start('$NOW');" >/dev/null 2>&1
  doas zfs snapshot ${SNAPSHOT_PREFIX}@$ROLLING_PREFIX-$NOW >/dev/null 2>&1
  doas -u postgres psql -q -c "SELECT pg_backup_stop();" >/dev/null 2>&1
EOF

snapshot_name="${SNAPSHOT_PREFIX}@$ROLLING_PREFIX-$NOW"
if [ -z "$latest_rolling_snapshot" ]; then
  send_snapshot_to_host "$snapshot_name" ""
else
  send_snapshot_to_host "$snapshot_name" "$latest_rolling_snapshot"
fi

# Remove old rolling snapshots to maintain a 24-hour window (24 snapshots)
cleanup_old_rolling_snapshots() {
  echo "Cleaning up old rolling snapshots..."
  ${SSH_CMD} <<EOF
      ${ZFS_CMD} list -t snapshot -o name -s creation | grep $SNAPSHOT_PREFIX@$ROLLING_PREFIX | head -n -$ROLLING_COUNT | xargs -I {} doas zfs destroy {}
EOF
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
