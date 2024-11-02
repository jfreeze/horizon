#!/bin/sh

# Script to add certbot renew command to crontab

USER=$(whoami)

# Parse options
while getopts ":u:" opt; do
  case $opt in
  u)
    USER="$OPTARG"
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    echo "Usage: $0 [-u user] host"
    exit 1
    ;;
  esac
done

shift $((OPTIND - 1))

if [ $# -lt 1 ]; then
  echo "Usage: $0 [-u user] host"
  exit 1
fi

HOST="$1"

# Run certbot renew once a week
CRON_JOB="0 0 * * 0 doas /usr/local/bin/certbot renew --quiet"

# SSH into the remote host and execute the commands
ssh "$USER@$HOST" /bin/sh <<EOF
# Check if the cron job already exists in the crontab
CRON_JOB='$CRON_JOB'
crontab -l 2>/dev/null | grep -F "\$CRON_JOB" >/dev/null 2>&1

if [ \$? -eq 0 ]; then
  echo "Cron job already exists."
else
  # Add the cron job to the current user's crontab
  (
    crontab -l 2>/dev/null
    echo "\$CRON_JOB"
  ) | crontab -
  echo "Cron job added successfully."
fi
EOF
