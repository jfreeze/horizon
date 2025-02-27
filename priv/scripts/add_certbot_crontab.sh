#!/bin/sh
# Generated with Horizon Version: 0.3.0

# Script to add certbot renew command to crontab

# Check arguments
if [ $# -ne 1 ]; then
  echo "Usage: $0 [user@]host (Horizon v0.3.0)"
  exit 1
fi

HOST="$1"

# Run certbot renew twice daily
CRON_JOB='0 0,12 * * * /usr/local/bin/doas /usr/local/bin/certbot renew --quiet --post-hook "/usr/local/bin/doas /usr/sbin/service nginx reload"'

# SSH into the remote host and execute the commands
ssh "$HOST" /bin/sh <<EOF
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
