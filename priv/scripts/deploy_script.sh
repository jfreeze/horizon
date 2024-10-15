#!/bin/sh

# File autogenerated by mix horizon.init (source: deploy_script.sh.eex)

set -ex

APP=$1
APP_PATH=$2

# Create the app user if it does not exist
if ! id -u "$APP" >/dev/null 2>&1; then
  doas pw user add -n "$APP" -c "Service user for $APP" -s /usr/sbin/nologin
  if [ $? -eq 0 ]; then
    echo "User '$username' added."
  else
    echo "[ERROR] Failed to add user '$username'."
    exit 1
  fi
fi

doas sysrc ${APP}_enable="YES"

# Create the app directory if it does not exist
if [ ! -d "$APP_PATH" ]; then
  doas mkdir -p "$APP_PATH/releases"
  doas chown "$APP" "$APP_PATH"
fi

# Extract the tarball to the app directory
doas sh -c "tar -xzf \"/tmp/$APP.tar.gz\" -C \"$APP_PATH\""
doas rm /tmp/$APP.tar.gz

# Ensure ownership of the app directory
doas chown -R $APP $APP_PATH

if [ ! -f "/usr/local/etc/rc.d/$APP" ]; then
  doas cp "$APP_PATH/rc_d/$APP" "/usr/local/etc/rc.d/$APP"
fi

# Restart the app service
doas service $APP restart