#!/bin/sh
# Generated with Horizon Version: 0.3.0

set -u

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
# bsd_install_script \
#   --output-format=[ansi|json] \
#   --quiet \
#   --pkg git \
#   --path /usr/local/lib/erlang27/bin \
#   --dot-path some/additional/path \
#   --service postgresql \
#   --postgres-init \
#	  --postgres-db-us_utf8_full mydb1 \
#	  --postgres-db-c_mixed_utf8 mydb2 \

# Default output format and quiet mode
OUTPUT_FORMAT="ansi"
QUIET="false"
VERBOSE="false"
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

log() {
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
	esac
	doas printf "$(date '+%Y-%m-%d %H:%M:%S') $LABEL $MESSAGE\n" | tee -a "$LOG_FILE"
}

#
# Function: puts status message
#
# Description:
#
#   Outputs messages based on state: success, error, debug, info, warn.
#
puts() {
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
		printf "${COLOR}${LABEL} ${MESSAGE}${RESET}\n"
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
		printf "${RED}[ERROR]${RESET} Unknown output format: ${OUTPUT_FORMAT}\n"
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
	--verbose)
		VERBOSE="true"
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
	--postgres-zfs-init)
		# no arguments to shift
		COMMANDS="$COMMANDS postgres-zfs-init"
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
	--dot-path)
		shift
		if [ -n "$1" ]; then
			echo "$1" >".path"
		else
			echo "${RED}[ERROR]${RESET} --dot-path requires an argument"
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
	puts "info" "Installing Elixir v$ELIXIR_VERSION..."
	WORKDIR=${WORKDIR:-$(mktemp -d -t elixir)}
	if [ ! -d "$WORKDIR" ]; then
		if ! run_cmd doas mkdir -p "$WORKDIR"; then
			puts "error" "Failed to create directory $WORKDIR."
			return 1
		fi
	fi
	cd "$WORKDIR" || {
		puts "error" "Failed to enter directory $WORKDIR."
		return 1
	}

	# Clone the Elixir repository
	if [ ! -d "elixir" ]; then
		if ! run_cmd git clone https://github.com/elixir-lang/elixir.git; then
			puts "error" "Failed to clone Elixir repository."
			return 1
		fi
	else
		puts "info" "Elixir repository already cloned."
	fi

	cd elixir || {
		puts "error" "Failed to enter elixir directory."
		return 1
	}

	# Fetch tags and checkout the desired version
	if ! run_cmd git fetch --tags; then
		puts "error" "Failed to fetch tags"
		cd ..
		return 1
	fi

	if ! run_cmd git checkout "v$ELIXIR_VERSION"; then
		puts "error" "Git checkout command failed for v$ELIXIR_VERSION"
		cd ..
		return 1
	else
		current_tag=$(git describe --tags --abbrev=0)
		if [ "$current_tag" = "v$ELIXIR_VERSION" ]; then
			puts "success" "Successfully checked out Elixir version: $current_tag"
		else
			puts "error" "Failed to checkout correct version. Requested v$ELIXIR_VERSION but got: $current_tag"
			cd ..
			return 1
		fi
	fi

	# Compile Elixir
	if ! run_cmd gmake; then
		puts "error" "Failed to build Elixir."
		cd ..
		return 1
	fi

	# Install Elixir
	if ! run_cmd doas gmake install; then
		puts "error" "Failed to install Elixir."
		cd ..
		return 1
	fi

	cd ..
	puts "success" "Elixir v$ELIXIR_VERSION installed successfully."
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
	ifconfig | awk '/inet / && $2 != "127.0.0.1" {print $2; exit}'
}

#
# Function: ip_address
#
# Description:
#
#     Get the IP addresses of the current host.
#
ip_addresses_list() {
	ifconfig | awk '/inet / && $2 != "127.0.0.1" {print $2}' | paste -sd ',' -
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
	password=$(openssl rand -hex 24)
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
	puts "success" "Username: $username"
	puts "success" "Password: $password"
	puts "success" "Database: $DB"
	puts "warn" "Record these credentials in a secure location."
	puts "warn" "You will not be able to retrieve the password later."
}

#
# Function: init_zfs
#
# Description:
#
#     Initializes zfs dataset for Postgres
#
init_zfs() {
	postgres_dataset=zroot/var/db_postgres

	if zfs list | grep -q "zroot/var/db_postgres"; then
		puts "info" "/var/db/postgres already exists."
		puts "warn" "Must manually manage dataset setup if needed."
	else
		doas zfs create -o mountpoint=/var/db/postgres $postgres_dataset
		doas zfs set compression=lz4 $postgres_dataset
		doas zfs set recordsize=32K $postgres_dataset
		doas zfs set primarycache=metadata $postgres_dataset
	fi
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
	# Get the current major version of the installed PostgreSQL
	PG_VERSION=$(pkg info postgresql* | grep -Eo 'postgresql[0-9]+-client' | sed -E 's/postgresql([0-9]+)-client/\1/')
	POSTGRES_CONF_FILE="${POSTGRES_DB_PATH}/data${PG_VERSION}/postgresql.conf"

	# Configure Sysrc
	if run_cmd doas sysrc postgresql_enable="YES"; then
		puts "success" "[INFO] Enabled postgresql service."
	else
		puts "error" "[ERROR] Failed to enable postgresql in /etc/rc.conf."
		exit_message
		exit 1
	fi

	# Run initdb if the data directory doesn't exist
	DBPATH="${POSTGRES_DB_PATH}/data${PG_VERSION}"
	if [ ! -d "${DBPATH}" ]; then
		puts "info" "${DBPATH} not found, initializing database..."
		doas mkdir -p "${DBPATH}"
		doas chown -R postgres:postgres "${DBPATH}"
		doas service postgresql initdb
	else
		puts "info" "${DBPATH} already exists."
		return 0
	fi

	server_ip=$(ip_address)
	server_ip_list=$(ip_addresses_list)

	# Set the permissions
	hba="""
# TYPE  DATABASE        USER            ADDRESS                 METHOD

local   all             postgres                                peer
host    all             postgres        samenet         	md5
#host    all             postgres        0.0.0.0/0         	md5
host    replication     replicator      samenet         	md5

	### Database access rules
"""

	# Set the listen_address in postgresql.conf
	doas -u postgres sed -i '' "s/#listen_addresses = 'localhost'/listen_addresses = 'localhost,$server_ip_list'/" "${POSTGRES_CONF_FILE}"

	cat <<EOL | doas -u postgres tee -a "$POSTGRES_CONF_FILE" >/dev/null
log_min_messages = notice
log_min_error_statement = notice
log_checkpoints = on
log_lock_waits = on
#log_timezone = 'UTC'
log_connections = on
log_disconnections = on
log_duration = off
log_statement = 'ddl' # none, ddl, mod, all
EOL

	# Uncomment the log_timezone line if it exists
	doas -u postgres sed -i '' 's/^#\(log_timezone =.*\)/\1/' "$POSTGRES_CONF_FILE"
	puts "info" "Updated $POSTGRES_CONF_FILE with PostgreSQL logging settings."

	doas -u postgres sh -c "echo \"$hba\" > ${POSTGRES_DB_PATH}/data${PG_VERSION}/pg_hba.conf"

	doas service postgresql status || doas service postgresql start >/dev/null

	create_psql_history
	configure_postgres_logging
}

#
# Function: configure_postgres_logging
#
# Description:
#
#     Configure PostgreSQL logging
#
configure_postgres_logging() {
	postgres_log_file="/var/log/postgresql.log"
	syslog_conf_file="/etc/syslog.conf"

	# Return if /var/log/postgresql.log exists
	if [ -d $postgres_log_file ]; then
		puts "info" "$postgres_log_file already exists."
		return 0
	else
		doas touch $postgres_log_file
		doas chown postgres:wheel $postgres_log_file
	fi

	# Step 1: Create Syslog Configuration for PostgreSQL
	if [ ! -d /etc/syslog.d ]; then
		echo "Directory /etc/syslog.d does not exist. Creating it..."
		doas mkdir -p /etc/syslog.d
	fi

	echo "*.*    /var/log/postgresql.log" | doas tee /etc/syslog.d/postgres.conf >/dev/null
	puts "info" "Created /etc/syslog.d/postgres.conf with PostgreSQL logging configuration."

	# Step 2: Modify Syslog Configuration
	if grep -q "postgresql\.log" "$syslog_conf_file"; then
		echo "[INFO] PostgreSQL log file already exists. Skipping changes."
	else
		if [ -f "$syslog_conf_file" ]; then
			# Uncomment the relevant line if it is commented
			doas sed -i '' 's/^#\(*.notice;authpriv.none;kern.debug;lpr.info;mail.crit;news.err\)/\1/' "$syslog_conf_file"
			# Update the line to add local0.none
			doas sed -i '' 's/\*.notice;authpriv.none;kern.debug;lpr.info;mail.crit;news.err/\*.notice;authpriv.none;kern.debug;lpr.info;mail.crit;news.err;local0.none/' "$syslog_conf_file"
			# Add the PostgreSQL logging line
			echo "local0.*			/var/log/postgresql.log" | doas tee -a "$syslog_conf_file" >/dev/null
			echo "[INFO] Updated $syslog_conf_file with PostgreSQL logging configuration."
		else
			puts "error" "$syslog_conf_file does not exist."
			return 1
		fi

	fi

	# Step 4: Restart Services
	doas service postgresql reload
	puts "info" "Reloaded PostgreSQL service."
	doas service syslogd restart
	puts "info" "Restarted syslogd service."
}

#
# Function: create_psql_history
#
# Description:
#
# 	 Create a .psql_history file for the postgres user
#
create_psql_history() {
	# Create a .psql_history file for the postgres user
	PSQL_HISTORY_FILE="/var/db/postgres/.psql_history"
	if [ ! -f "$PSQL_HISTORY_FILE" ]; then
		doas touch "$PSQL_HISTORY_FILE"
		doas chown postgres "$PSQL_HISTORY_FILE"
		puts "info" "Created $PSQL_HISTORY_FILE for the postgres user."
	else
		puts "info" "$PSQL_HISTORY_FILE already exists."
	fi
}

#
# Function: create_db
#
# Description:
#
#    Create a new user, password and database. User supplied database name.
#
create_db() {
	POSTGRES_DB_PATH=/var/db/postgres
	# Get the current major version of the installed PostgreSQL
	PG_VERSION=$(pkg info postgresql* | grep -Eo 'postgresql[0-9]+-client' | sed -E 's/postgresql([0-9]+)-client/\1/')
	POSTGRES_HBA_FILE="${POSTGRES_DB_PATH}/data${PG_VERSION}/pg_hba.conf"

	# Ensure the server is running
	doas service postgresql status || doas service postgresql start >/dev/null

	generate_credentials
	create_user_sql="CREATE USER \"${username}\" WITH PASSWORD '${password}';"

	if run_cmd doas -u postgres psql -c "$create_user_sql"; then
		puts "success" "User ${username} created successfully."
	else
		puts "error" "Failed to create user '${username}'."
		exit_message
		exit 1
	fi

	#                 |  Collate     | Ctype
	#  c_mixed_utf8   |  C           | C.UTF-8
	#  c_utf8_full    |  C.UTF-8     | C.UTF-8
	#  us_utf8_full   |  en_US.UTF-8 | en_US.UTF-8

	create_db_sql="CREATE DATABASE \"${DB}\" OWNER \"${username}\" ${ENCODING};"

	if run_cmd doas -u postgres psql -c "$create_db_sql"; then
		puts "success" "Database $DB created successfully."
	else
		puts "error" "Failed to create database $DB. See /var/log/postgresql.log for more information."
		doas tail -n 5 /var/log/postgresql.log >&2
		exit_message
		exit 1
	fi

	server_ip=$(ip_address)

	if run_cmd doas -u postgres sh -c "cat >> ${POSTGRES_HBA_FILE} << EOF
host    ${DB}           ${username}           samenet        md5
#host    ${DB}           ${username}           0.0.0.0/0      md5
EOF
"; then
		puts "success" "Added user ${username}@${DB} to pg_hba.conf."
	else
		puts "error" "Failed to add entries to pg_hba.conf."
		exit_message
		exit 1
	fi

	if run_cmd doas service postgresql reload; then
		puts "success" "Postgres reloaded successfully."
	else
		puts "error" "Failed to reload Postgres."
		exit_message
		exit 1
	fi

	echo_credentials
}

#
# Function: update_path
#
# Description:
#
#   Updates the PATH environment variable by adding the binary path of specified packages.
#   The update is also appended to the .shrc file and to .ssh/environment to persist across sessions.
#   Supports both exact and partial package name matching.
#
# Usage:
#   update_path package_name1 package_name2 ...
#
# ## Example:
#
# update_path erlang-runtime27-27.0
#
update_path() {
	# Define the shell RC file (modify if using a different shell)
	RC_FILE="$HOME/.shrc"
	SSH_ENV_FILE="$HOME/.ssh/environment"

	# Ensure the RC file exists; create it if it doesn't
	if [ ! -f "$RC_FILE" ]; then
		touch "$RC_FILE" || {
			echo "❌  Failed to create $RC_FILE"
			return 1
		}
	fi

	# Ensure the SSH_ENV file exists; create it if it doesn't
	if [ ! -f "$SSH_ENV_FILE" ]; then
		touch "$SSH_ENV_FILE" || {
			echo "❌  Failed to create $RC_FILE"
			return 1
		}
		chmod 600 "$SSH_ENV_FILE"
	fi

	# Iterate over all provided package names
	for input_pkg in "$@"; do
		path=""

		# Check if the exact package exists
		exact_match=$(pkg info | awk -v pkg="$input_pkg" '$1 == pkg {print $1}')

		if [ -n "$exact_match" ]; then
			selected_pkg="$exact_match"
			puts "success" "Found exact match: $selected_pkg"
		else
			# If no exact match, treat input as partial and find matching packages
			matching_pkgs=$(pkg info | awk -v prefix="$input_pkg" '$1 ~ "^"prefix {print $1}')

			if [ -z "$matching_pkgs" ]; then
				puts "warn" "No installed packages match: $input_pkg"
				continue
			fi

			# Extract version numbers and sort numerically to find the latest version
			# Assumes package names follow the pattern name-version (e.g., erlang-runtime27-27.0)
			selected_pkg=$(echo "$matching_pkgs" | awk -v prefix="$input_pkg" '
                {
                    # Split the package name by "-"
                    n = split($0, parts, "-")
                    # The version is the last part
                    version = parts[n]
                    # Print version and full package name
                    print version, $0
                }
            ' | sort -n | tail -n 1 | awk '{print $2}')

			if [ -z "$selected_pkg" ]; then
				puts "warn" "No valid numeric version found for partial package: $input_pkg"
				continue
			fi

			if [ "$VERBOSE" = "true" ]; then
				echo "VERBOSE: $VERBOSE"
				echo "🔍  Selected package based on partial match: $selected_pkg"
			fi
		fi

		# Proceed only if a package has been selected
		if [ -n "$selected_pkg" ]; then
			# Determine extraction logic based on the package pattern
			case "$selected_pkg" in
			erlang-runtime*)
				# Method 1: Parse pkg info -D output to find the binary path
				path=$(pkg info -D "$selected_pkg" 2>/dev/null |
					grep 'binary path' |
					sed -n 's/.*binary path ["'"'"']\([^"'"'"']*\)["'"'"'].*/\1/p')

				# If Method 1 fails, try Method 2
				if [ -z "$path" ]; then
					# Method 2: Find the directory containing 'erl' binary
					erl_binary=$(pkg info -l "$selected_pkg" 2>/dev/null |
						grep "bin/erl\$" |
						grep -v "erts")

					if [ -n "$erl_binary" ]; then
						path=$(dirname "$erl_binary")
					fi
				fi
				;;

			# Add additional package cases here
			# Example:
			# another-pkg*)
			#     # Extraction logic for another-pkg
			#     ;;

			*)
				if [ "$VERBOSE" = "true" ]; then
					puts "info" "No extraction logic defined for package: $selected_pkg"
				fi
				continue
				;;
			esac

			# Check if the path was successfully extracted
			if [ -n "$path" ]; then
				# Trim leading and trailing whitespace from the path
				trimmed_path=$(printf '%s' "$path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

				# Verify that trimming was successful and path is not empty
				if [ -z "$trimmed_path" ]; then
					puts "info" "❌  Extracted path is empty after trimming for package: $selected_pkg"
					continue
				fi

				# Check if the trimmed path is already in the current PATH
				echo "$PATH" | tr ':' '\n' | grep -Fxq "$trimmed_path"
				if [ $? -ne 0 ]; then
					# Prepend the new path to PATH
					export PATH="$trimmed_path:$PATH"
					puts "success" "✅  Updated PATH with: $trimmed_path"
				else
					puts "info" "🔍  Path already exists in PATH: $trimmed_path"
				fi

				# Prepare the export line for the RC file
				export_line="export PATH=\"$trimmed_path:\$PATH\""

				# Check if the export line already exists in the RC file
				grep -Fxq "$export_line" "$RC_FILE"
				if [ $? -ne 0 ]; then
					# Append the export line to the RC file
					echo "$export_line" >>"$RC_FILE" &&
						puts "info" "Added PATH update to $RC_FILE"
				else
					puts "info" "PATH update already exists in $RC_FILE"
				fi

				# Prepare the path line for the SSH_ENV file
				default_path=$(awk '/^default/,/^$/' /etc/login.conf | grep 'path=' | head -n 1 | cut -d '=' -f 2 | tr ' ' ':' | sed 's|~|'$HOME'|' | sed 's|[:\\]*$||')
				path_line="PATH=$trimmed_path:$default_path"

				# Check if the path line already exists in the SSH_ENV file
				grep -Fxq "$path_line" "$SSH_ENV_FILE"
				if [ $? -ne 0 ]; then
					# Append the path line to the SSH_ENV file
					echo "$path_line" >>"$SSH_ENV_FILE" &&
						puts "info" "Added PATH update to $SSH_ENV_FILE"
				else
					puts "info" "PATH update already exists in $SSH_ENV_FILE"
				fi

			else
				puts "error" "❌  Failed to extract path for package: $selected_pkg"
			fi
		else
			puts "error" "❌  No package selected for input: $input_pkg"
		fi
	done
	return 0
}

# Process commands in the order they were provided
for CMD in $COMMANDS; do
	case "$CMD" in
	pkg:*)
		APP="${CMD#pkg:}"
		# Check if package is installed
		if pkg info "$APP" >/dev/null 2>&1; then
			puts "info" "$APP is already installed."
		else
			# Try to install the package
			if run_cmd doas pkg install -y "$APP"; then
				puts "info" "$APP installed successfully."
			else
				puts "error" "[ERROR] Failed to install $APP."
				exit_message
				exit 1
			fi
		fi
		echo "Updating PATH for $APP"
		update_path $APP
		;;
	service:*)
		SERVICE="${CMD#service:}"
		# Enable and start the service
		if run_cmd doas sysrc "${SERVICE}_enable=YES"; then
			puts "info" "$SERVICE service enabled."
		else
			puts "error" "Failed to enable $SERVICE service."
		fi

		# Check if the service is already running
		doas service "$SERVICE" status >/dev/null 2>&1
		SERVICE_STATUS=$?

		if [ $SERVICE_STATUS -eq 0 ]; then
			puts "info" "$SERVICE service is already running."
		else
			# Attempt to start the service
			if run_cmd doas service "$SERVICE" start; then
				puts "success" "[INFO] $SERVICE service started."
			else
				puts "error" "[ERROR] Failed to start $SERVICE service."
			fi
		fi
		;;
	elixir)
		# Handle Elixir installation
		if [ -z "$ELIXIR_VERSION" ]; then
			puts "error" "--elixir option requires a version."
			exit_message
			exit 1
		fi
		if is_elixir_installed; then
			puts "info" "Elixir v$ELIXIR_VERSION is already installed."
		else
			if install_elixir; then
				puts "info" "Elixir v$ELIXIR_VERSION installed successfully."
			else
				puts "error" "Failed to install Elixir v$ELIXIR_VERSION."
				exit_message
				exit 1
			fi
		fi
		;;
	postgres-zfs-init)
		# Handle zfs setup for Postgres
		init_zfs
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
		puts "error" "Unknown command: $CMD"
		exit 1
		;;
	esac
done

exit_message
