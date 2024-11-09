#!/bin/sh

# Script to turn on PostgreSQL access for user 'postgres' from external IPs with /0 netmask over SSH
# Usage: ./turn_on_postgres_access.sh [user@]remote_host

if [ -z "$1" ]; then
  echo "Usage: $0 [user@]remote_host"
  exit 1
fi

REMOTE_HOST="$1"

# Commands to execute on the remote host
ssh "$REMOTE_HOST" 'sh -s' <<'ENDSSH'
PG_HBA_CONF=$(doas -u postgres psql -c "SHOW hba_file;")

# Uncomment lines granting access to 'postgres' from any IP with /0 netmask
sed -i.bak -E '/^[[:space:]]*#[[:space:]]*host[[:space:]]+all[[:space:]]+postgres[[:space:]]+[0-9\.]+\/0[[:space:]]+/ s|^[[:space:]]*#[[:space:]]*||' "$PG_HBA_CONF"

# Reload PostgreSQL configuration
doas service postgresql reload
ENDSSH
