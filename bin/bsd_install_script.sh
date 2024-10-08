#!/bin/sh

set -euo pipefail

#
# The script that does the actual install on the remote host.
# This script is self contained and runs on the target host machine.
#
# This script is typically called by calling bsd_install.sh from the remote host.
#
# You can run this script directly on the target host:
#
# ## Example on target host
#
#    bsd_install_script.sh --postgres-init
#

# add this to usage docs
# bsd_install_script --output-format=[ansi|json] --quiet --pkg git --path /usr/local/lib/erlang27/bin --service postgresql --postgres-init

# Default output format and quiet mode
OUTPUT_FORMAT="ansi"
QUIET="false"
ELIXIR_VERSION=""
COMMANDS="" # Use a string to store commands
CUSTOM_PATHS=""

# Define colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[0;37m'
RESET='\033[0m' # No Color

## todo: add logging
LOG_FILE="/var/log/bsd_install.log"

log_info() {
    doas echo -e "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" | tee -a "$LOG_FILE"
}

log_error() {
    doas echo -e "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" | tee -a "$LOG_FILE" >&2
}

#
# Function: output_message
#
# Description:
#
#   Outputs messages based on state: success, error, debug, info, warn.
#
output_message() {
    STATUS="$1"
    MESSAGE="$2"

    case $STATUS in
    success)
        COLOR=$GREEN
        LABEL="[SUCCESS]"
        ;;
    error)
        COLOR=$RED
        LABEL="[ERROR]"
        ;;
    debug)
        COLOR=$YELLOW
        LABEL="[DEBUG]"
        ;;
    info)
        COLOR=$YELLOW
        LABEL="[INFO]"
        ;;
    warn)
        COLOR=$YELLOW
        LABEL="[WARN]"
        ;;
    *)
        COLOR=$WHITE
        LABEL=""
        ;;
    esac

    case "$OUTPUT_FORMAT" in
    ansi)
        echo -e "${COLOR}${LABEL} ${MESSAGE}${RESET}"
        ;;
    json)
        # Escape quotes and backslashes in message
        ESCAPED_MESSAGE=$(echo "$MESSAGE" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
        # Append JSON object to JSON_MESSAGES
        if [ -z "$JSON_MESSAGES" ]; then
            JSON_MESSAGES="{\"status\":\"$STATUS\",\"message\":\"$ESCAPED_MESSAGE\"}"
        else
            JSON_MESSAGES="${JSON_MESSAGES}, {\"status\":\"$STATUS\",\"message\":\"$ESCAPED_MESSAGE\"}"
        fi
        ;;
    *)
        echo -e "${RED}[ERROR]${RESET} Unknown output format: $OUTPUT_FORMAT"
        exit 1
        ;;
    esac
}

exit_message() {
    # Output JSON_MESSAGES if in JSON format
    if [ "$OUTPUT_FORMAT" = "json" ]; then
        echo "[${JSON_MESSAGES}]"
    fi
}

#
# Parse command-line arguments
#
while [ $# -gt 0 ]; do
    case "$1" in
    --output-format=*)
        OUTPUT_FORMAT="${1#*=}"
        ;;
    --quiet)
        QUIET="true"
        ;;
    --pkg)
        shift
        if [ -n "$1" ]; then
            COMMANDS="$COMMANDS pkg:$1"
        else
            echo "${RED}[ERROR]${RESET} --pkg requires an argument"
            exit 1
        fi
        ;;
    --service)
        shift
        if [ -n "$1" ]; then
            COMMANDS="$COMMANDS service:$1"
        else
            echo "${RED}[ERROR]${RESET} --service requires an argument$"
            exit 1
        fi
        ;;
    --elixir)
        shift
        if [ -n "$1" ]; then
            ELIXIR_VERSION="$1"
            COMMANDS="$COMMANDS elixir"
        else
            echo "${RED}[ERROR]${RESET} --elixir requires a version argument"
            exit 1
        fi
        ;;
    --postgres-init)
        # no arguments to shift
        COMMANDS="$COMMANDS postgres-init"
        ;;
    --postgres-db-c_mixed_utf8)
        shift
        if [ -n "$1" ]; then
            COMMANDS="$COMMANDS postgres-db-c_mixed_utf8:$1"
        else
            echo "${RED}[ERROR]${RESET} --postgres-db-c_mixed_utf8 requires a database name argument"
            exit 1
        fi
        ;;
    --postgres-db-c_utf8_full)
        shift
        if [ -n "$1" ]; then
            COMMANDS="$COMMANDS postgres-db-c_utf8_full:$1"
        else
            echo "${RED}[ERROR]${RESET} --postgres-db-c_utf8_full requires a database name argument"
            exit 1
        fi
        ;;
    --postgres-db-us_utf8_full)
        shift
        if [ -n "$1" ]; then
            COMMANDS="$COMMANDS postgres-db-us_utf8_full:$1"
        else
            echo "${RED}[ERROR]${RESET} --postgres-db-us_utf8_full requires a database name argument"
            exit 1
        fi
        ;;
    --path)
        shift
        if [ -n "$1" ]; then
            CUSTOM_PATHS="$1:$CUSTOM_PATHS"
        else
            echo "${RED}[ERROR]${RESET} --path requires an argument"
            exit 1
        fi
        ;;
    *)
        # Unknown option
        echo "Unknown option: '$1'"
        exit 1
        ;;
    esac
    shift
done

# Update PATH with custom paths
if [ -n "$CUSTOM_PATHS" ]; then
    PATH="$CUSTOM_PATHS$PATH"
    export PATH
fi

# Initialize JSON_MESSAGES
JSON_MESSAGES=""

#
# Function: run_cmd
#
# Description:
#
#   Run commands with optional quiet mode
#

run_cmd() {
    if [ "$QUIET" = "true" ]; then
        "$@" >/dev/null 2>&1
    else
        "$@"
    fi
    return $?
}

# Function to check if Elixir is installed
is_elixir_installed() {
    if command -v elixir >/dev/null 2>&1; then
        INSTALLED_VERSION=$(elixir --version | grep 'Elixir' | awk '{print $2}')
        if [ "$INSTALLED_VERSION" = "$ELIXIR_VERSION" ]; then
            return 0 # Elixir is installed and version matches
        else
            return 1 # Elixir is installed but version differs
        fi
    else
        return 1 # Elixir is not installed
    fi
}

#
# Function to install Elixir
#
# Description:
#
#     Install Elixir from source
#
install_elixir() {
    output_message "info" "Installing Elixir v$ELIXIR_VERSION..."
    WORKDIR=${WORKDIR:-$(mktemp -d -t elixir)}
    if [ ! -d "$WORKDIR" ]; then
        if ! run_cmd doas mkdir -p "$WORKDIR"; then
            output_message "error" "Failed to create directory $WORKDIR."
            return 1
        fi
    fi
    cd "$WORKDIR" || {
        output_message "error" "Failed to enter directory $WORKDIR."
        return 1
    }

    # Clone the Elixir repository
    if [ ! -d "elixir" ]; then
        if ! run_cmd git clone https://github.com/elixir-lang/elixir.git; then
            output_message "error" "Failed to clone Elixir repository."
            return 1
        fi
    else
        output_message "info" "Elixir repository already cloned."
    fi

    cd elixir || {
        output_message "error" "Failed to enter elixir directory."
        return 1
    }

    # Fetch tags and checkout the desired version
    if ! run_cmd git fetch --tags && run_cmd git checkout "v$ELIXIR_VERSION"; then
        output_message "error" "Failed to checkout Elixir version v$ELIXIR_VERSION."
        cd ..
        return 1
    fi

    # Compile Elixir
    if ! run_cmd gmake; then
        output_message "error" "Failed to build Elixir."
        cd ..
        return 1
    fi

    # Install Elixir
    if ! run_cmd doas gmake install; then
        output_message "error" "Failed to install Elixir."
        cd ..
        return 1
    fi

    cd ..
    output_message "success" "Elixir v$ELIXIR_VERSION installed successfully."
    return 0
}

#
# Function: ip_address
#
# Description:
#
#     Get the IP address of the current host.
#
ip_address() {
    ifconfig | awk '/inet / && $2 != "127.0.0.1" {print $2}'
}

#
# Function: generate_credentials
#
# Description:
#
#     Generate username and password
#
generate_credentials() {
    username=$(uuidgen)
    password=$(openssl rand -base64 32 | tr -d '=')
}

#
# Function: echo_credentials
#
# Description:
#
#     Echo the username, password, and database name.
#
# Usage:
#
#     echo_credentials $database_name
#
echo_credentials() {
    output_message "success" "Username: $username"
    output_message "success" "Password: $password"
    output_message "success" "Database: $DB"
    output_message "warn" "Record these credentials in a secure location."
    output_message "warn" "You will not be able to retrieve the password later."
}

#
# Function: init_postgres
#
# Description:
#
#     Initializes Postgres server
#
init_postgres() {
    POSTGRES_DB_PATH=/var/db/postgres

    # Configure Sysrc
    if run_cmd doas sysrc postgresql_enable="YES"; then
        output_message "success" "[INFO] Enabled postgresql service."
    else
        output_message "error" "[ERROR] Failed to enable postgresql in /etc/rc.conf."
        exit_message
        exit 1
    fi

    # Run initdb if the data directory doesn't exist

    # Get the current major version of the installed PostgreSQL
    pg_version=$(pkg info postgresql* | grep -Eo 'postgresql[0-9]+-client' | sed -E 's/postgresql([0-9]+)-client/\1/')

    # Check if ${POSTGRES_DB_PATH}/data$vsn directory exists
    if [ ! -d "${POSTGRES_DB_PATH}/data${pg_version}" ]; then
        output_message "info" "${POSTGRES_DB_PATH}/data${pg_version} not found, initializing database..."
        doas service postgresql initdb
    else
        output_message "info" "${POSTGRES_DB_PATH}/data${pg_version} already exists."
        return 0
    fi

    # Set the listen_address in postgresql.conf
    server_ip=$(ip_address)
    listen_addresses="listen_addresses = 'localhost, ${server_ip}'  # what IP address(es) to listen on;"
    doas -u postgres sh -c "echo $listen_addresses >>\"$POSTGRES_DB_PATH/data${pg_version}/postgresql.conf\""

    # Set the permissions
    hba="""
# TYPE  DATABASE        USER            ADDRESS                 METHOD

local   all             postgres                                peer
host    all             postgres        ${server_ip}/24         md5
host    replication     replicator      ${server_ip}/24         md5

### Database access rules
"""
    doas -u postgres sh -c "echo \"$hba\" > ${POSTGRES_DB_PATH}/data${pg_version}/pg_hba.conf"

    # Start the server
    doas service postgresql start
}

#
# Function: create_db
#
# Description:
#
#    Create a new user, password and database. User supplied database name.
#
create_db() {
    generate_credentials
    create_user_sql="CREATE USER \"${username}\" WITH PASSWORD '${password}';"

    if run_cmd doas -u postgres psql -c "$create_user_sql"; then
        output_message "success" "User ${username} created successfully."
    else
        output_message "error" "Failed to create user '${username}'i."
        exit_message
        exit 1
    fi

    #                                                |  Collate     | Ctype
    #  c_mixed_utf8   |  C           | C.UTF-8
    #  c_utf8_full    |  C.UTF-8     | C.UTF-8
    #  us_utf8_full   |  en_US.UTF-8 | en_US.UTF-8

    create_db_sql="CREATE DATABASE \"${DB}\" OWNER \"${username}\" ${ENCODING};"

    if run_cmd doas -u postgres psql -c "$create_db_sql"; then
        output_message "success" "Database $DB created successfully."
    else
        output_message "error" "Failed to create database $DB."
        exit_message
        exit 1
    fi

    server_ip=$(ip_address)
    hba="host    ${DB}           ${username}           ${server_ip}/24        md5"

    if run_cmd doas -u postgres sh -c "echo \"$hba\" >> ${POSTGRES_DB_PATH}/data${pg_version}/pg_hba.conf"; then
        output_message "success" "Added user ${username}@${DB} to pg_hba.conf."
    else
        output_message "error" "Failed to add host ${server_ip} to pg_hba.conf."
        exit_message
        exit 1
    fi

    if run_cmd doas service postgresql reload; then
        output_message "success" "Postgres reloaded successfully."
    else
        output_message "error" "Failed to reload Postgres."
        exit_message
        exit 1
    fi

    echo_credentials
}

# Process commands in the order they were provided
for CMD in $COMMANDS; do
    case "$CMD" in
    pkg:*)
        APP="${CMD#pkg:}"
        # Check if package is installed
        if pkg info "$APP" >/dev/null 2>&1; then
            output_message "info" "$APP is already installed."
        else
            # Try to install the package
            if run_cmd doas pkg install -y "$APP"; then
                output_message "success" "[INFO] $APP installed successfully."
            else
                output_message "error" "[ERROR] Failed to install $APP."
                exit_message
                exit 1
            fi
        fi
        ;;
    service:*)
        SERVICE="${CMD#service:}"
        # Enable and start the service
        if run_cmd doas sysrc "${SERVICE}_enable=YES"; then
            output_message "info" "$SERVICE service enabled."
        else
            output_message "error" "Failed to enable $SERVICE service."
        fi

        # Check if the service is already running
        run_cmd doas service "$SERVICE" status
        SERVICE_STATUS=$?

        if [ $SERVICE_STATUS -eq 0 ]; then
            output_message "info" "$SERVICE service is already running."
        else
            # Attempt to start the service
            if run_cmd doas service "$SERVICE" start; then
                output_message "success" "[INFO] $SERVICE service started."
            else
                output_message "error" "[ERROR] Failed to start $SERVICE service."
            fi
        fi
        ;;
    elixir)
        # Handle Elixir installation
        if [ -z "$ELIXIR_VERSION" ]; then
            output_message "error" "--elixir option requires a version."
            exit_message
            exit 1
        fi
        if is_elixir_installed; then
            output_message "info" "Elixir v$ELIXIR_VERSION is already installed."
        else
            if install_elixir; then
                output_message "info" "Elixir v$ELIXIR_VERSION installed successfully."
            else
                output_message "error" "Failed to install Elixir v$ELIXIR_VERSION."
                exit_message
                exit 1
            fi
        fi
        ;;
    postgres-init)
        # Handle Postgres configuration
        init_postgres
        ;;
    postgres-db-c_mixed_utf8:*)
        DB="${CMD#postgres-db-c_mixed_utf8:}"
        ENCODING=""
        create_db
        ;;
    postgres-db-c_utf8_full:*)
        DB="${CMD#postgres-db-c_utf8_full:}"
        ENCODING="ENCODING 'UTF8' LC_COLLATE = 'C.UTF-8' LC_CTYPE = 'C.UTF-8' TEMPLATE template0"
        create_db
        ;;
    postgres-db-us_utf8_full:*)
        DB="${CMD#postgres-db-us_utf8_full:}"
        ENCODING="ENCODING 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8' TEMPLATE template0"
        create_db
        ;;
    *)
        output_message "error" "Unknown command: $CMD"
        exit 1
        ;;
    esac
done

exit_message
