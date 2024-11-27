#!/bin/sh

# Default values for optional arguments
PORT="5432"
USER="postgres"

# Parse optional arguments
while getopts "p:U:" opt; do
    case $opt in
    p)
        PORT="$OPTARG"
        ;;
    U)
        USER="$OPTARG"
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        echo "Usage: $0 [-p port] [-U user] db_name target_user host"
        exit 1
        ;;
    esac
done

# Shift off the options and their arguments
shift $((OPTIND - 1))

# Check for required positional arguments
if [ $# -lt 3 ]; then
    echo "Error: Missing required arguments."
    echo "Usage: $0 [-p port] [-U user] db_name target_user host"
    exit 1
fi

# Assign positional arguments
DB_NAME="$1"
TARGET_USER="$2"
HOST="$3"

# Execute SQL commands quietly
psql -q -h "$HOST" -p "$PORT" -U "$USER" -d "$DB_NAME" <<EOF

\set QUIET on

-- Change ownership of all tables
DO \$\$
DECLARE
    obj RECORD;
BEGIN
    FOR obj IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
        EXECUTE 'ALTER TABLE public.' || quote_ident(obj.tablename) || ' OWNER TO "$TARGET_USER"';
    END LOOP;
END
\$\$;

-- Change ownership of all sequences
DO \$\$
DECLARE
    obj RECORD;
BEGIN
    FOR obj IN SELECT sequencename FROM pg_sequences WHERE schemaname = 'public' LOOP
        EXECUTE 'ALTER SEQUENCE public.' || quote_ident(obj.sequencename) || ' OWNER TO "$TARGET_USER"';
    END LOOP;
END
\$\$;

-- Change ownership of all views
DO \$\$
DECLARE
    obj RECORD;
BEGIN
    FOR obj IN SELECT viewname FROM pg_views WHERE schemaname = 'public' LOOP
        EXECUTE 'ALTER VIEW public.' || quote_ident(obj.viewname) || ' OWNER TO "$TARGET_USER"';
    END LOOP;
END
\$\$;

-- Change ownership of all functions
DO \$\$
DECLARE
    obj RECORD;
BEGIN
    FOR obj IN SELECT proname, pg_get_function_identity_arguments(p.oid) AS args
               FROM pg_proc p 
               JOIN pg_namespace n ON p.pronamespace = n.oid 
               WHERE n.nspname = 'public' LOOP
        EXECUTE 'ALTER FUNCTION public.' || quote_ident(obj.proname) || '(' || obj.args || ') OWNER TO "$TARGET_USER"';
    END LOOP;
END
\$\$;

\set QUIET off
EOF

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

if [ $? -eq 0 ]; then
    printf "${GREEN}Database owner updated successfully${RESET}\n"
else
    printf "${RED}Errors may have occured updating database owner${RESET}\n"
fi
