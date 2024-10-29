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
while getopts "u:h:" opt; do
  case $opt in
  u) USER="$OPTARG" ;;
  *) echo "Usage: $0 [-u user] host" && exit 1 ;;
  esac
done

HOST=${@:$OPTIND:1}
if [ -z "$HOST" ]; then
  echo "Host is required. Usage: $0 [-u user] host"
  exit 1
fi

# SSH and ZFS commands
SSH_CMD="ssh -T ${USER}@${HOST}"
SSH_CMD="ssh -T -o LogLevel=error ${USER}@$HOST"
ZFS_CMD="doas zfs"

# Get the list of existing rolling and daily snapshots
get_latest_snapshot() {
  ${SSH_CMD} "${ZFS_CMD} list -t snapshot -o name -s creation | grep $SNAPSHOT_PREFIX@$1" | tail -1
}

# Send the snapshot to the controlling host
send_snapshot_to_host() {
    local snapshot_name=$1
    local previous_snapshot=$2

    if [ -z "$previous_snapshot" ]; then
        echo "Sending full snapshot $snapshot_name to controlling host..."
        ${SSH_CMD} << EOF
          doas zfs send -vcR $snapshot_name | ssh ${USER}@$(hostname) "doas zfs receive -F $SNAPSHOT_PREFIX"
EOF
    else
        echo "Sending incremental snapshot from $previous_snapshot to $snapshot_name..."
        ${SSH_CMD} << EOF
          doas zfs send -vcRI $previous_snapshot $snapshot_name | ssh ${USER}@$(hostname) "doas zfs receive -F $SNAPSHOT_PREFIX"
EOF
    fi
}

# Take daily snapshot
take_daily_snapshot() {
  echo "Taking a daily snapshot..."
  ${SSH_CMD} <<EOF
    doas zfs snapshot ${SNAPSHOT_PREFIX}@$DAILY_PREFIX-$NOW
EOF
}

# Remove old daily snapshots beyond retention period
cleanup_old_daily_snapshots() {
  echo "Cleaning up old daily snapshots..."
  ${SSH_CMD} <<EOF
      doas zfs list -t snapshot -o name -s creation | grep $SNAPSHOT_PREFIX@$DAILY_PREFIX | head -n -$RETENTION_DAYS | xargs -I {} doas zfs destroy {}
EOF
}

# Remove old rolling snapshots to maintain a 24-hour window (24 snapshots)
cleanup_old_rolling_snapshots() {
  echo "Cleaning up old rolling snapshots..."
  ${SSH_CMD} <<EOF
      doas zfs list -t snapshot -o name -s creation | grep $SNAPSHOT_PREFIX@$ROLLING_PREFIX | head -n -$ROLLING_COUNT | xargs -I {} doas zfs destroy {}
EOF
}

# Get the number of rolling snapshots
count_rolling_snapshots() {
  ${SSH_CMD} "${ZFS_CMD} list -t snapshot -o name | grep $SNAPSHOT_PREFIX@$ROLLING_PREFIX" | wc -l
}


# Main script execution
latest_rolling_snapshot=$(get_latest_snapshot "$ROLLING_PREFIX")

# Single SSH call for PostgreSQL backup and ZFS snapshot creation
echo "Running PostgreSQL backup and creating ZFS snapshot..."
${SSH_CMD} << EOF
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

# Clean up old rolling snapshots to maintain the 24-hour rolling window
cleanup_old_rolling_snapshots

# 2. Handle Daily Snapshots (at midnight only)
if [ "$(date +%H%M)" = "0000" ]; then
  # It's midnight, take a daily snapshot and clean up old daily snapshots
  take_daily_snapshot
  cleanup_old_daily_snapshots
fi

echo "Snapshot process completed."
