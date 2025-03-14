#!/bin/sh
# Generated with Horizon Version: 0.3.0

# Script to turn off PostgreSQL access for a specific user from external IPs with /0 netmask over SSH
# Usage: ./turn_off_user_access.sh db_user [user@]remote_host

if [ $# -lt 2 ]; then
  echo "Usage: $0 db_user [user@]remote_host (Horizon v0.3.0)"
  exit 1
fi

DB_USER="$1"
REMOTE_HOST="$2"

# Execute commands on the remote host
ssh "$REMOTE_HOST" "DB_USER='$DB_USER' sh -s" <<'ENDSSH'
# Get the path to pg_hba.conf
PG_HBA_CONF=$(doas -u postgres psql -Atc "SHOW hba_file;" | xargs)

# Ensure pg_hba.conf file exists
if [ -z "$PG_HBA_CONF" ] || ! doas test -f "$PG_HBA_CONF"; then
  echo "Error: pg_hba.conf file not found."
  exit 1
fi

# Define the pattern to search for (uncommented line)
PATTERN="^[[:space:]]*host[[:space:]]+[^[:space:]]+[[:space:]]+$DB_USER[[:space:]]+0\.0\.0\.0\/0[[:space:]]+md5"

if doas grep -Eq "$PATTERN" "$PG_HBA_CONF"; then
  doas sed -i.bak -E "/$PATTERN/ s|^[[:space:]]*|# &|" "$PG_HBA_CONF"
  echo "Commented out line for user '$DB_USER' in pg_hba.conf"
else
  echo "No active line found for user '$DB_USER' in pg_hba.conf"
fi

# Reload PostgreSQL configuration
doas service postgresql reload
ENDSSH
