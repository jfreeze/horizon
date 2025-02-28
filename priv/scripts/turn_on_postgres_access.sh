#!/bin/sh
# Generated with Horizon Version: 0.3.0

# Script to turn on PostgreSQL access for user 'postgres' from external IPs with /0 netmask over SSH
# Usage: ./turn_on_postgres_access.sh [user@]remote_host

if [ -z "$1" ]; then
  echo "Usage: $0 [user@]remote_host (Horizon v0.3.0)"
  exit 1
fi

REMOTE_HOST="$1"

# Commands to execute on the remote host
ssh "$REMOTE_HOST" 'sh -s' <<'ENDSSH'
# Get the path to pg_hba.conf
PG_HBA_CONF=$(doas -u postgres psql -Atc "SHOW hba_file;" | xargs)

# Ensure PG_HBA_CONF file exists
if ! doas test -f "$PG_HBA_CONF"; then
  echo "Error: pg_hba.conf file not found at '$PG_HBA_CONF'"
  exit 1
fi

# Ensure PG_HBA_CONF is not empty
if [ -z "$PG_HBA_CONF" ]; then
  echo "Error: pg_hba.conf file not found."
  exit 1
fi

# Uncomment lines granting access to 'postgres' from any IP with /0 netmask
doas sed -i.bak -E '/^[[:space:]]*#[[:space:]]*host[[:space:]]+all[[:space:]]+postgres[[:space:]]+[0-9\.]+\/0[[:space:]]+/ s|^[[:space:]]*#[[:space:]]*||' "$PG_HBA_CONF"

# Reload PostgreSQL configuration
doas service postgresql reload
ENDSSH
