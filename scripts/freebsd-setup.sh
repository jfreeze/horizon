#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

# Function to display informational messages
info() {
  printf "\033[1;34m[INFO]\033[0m %s\n" "$1"
}

# Function to display error messages
error() {
  printf "\033[1;31m[ERROR]\033[0m %s\n" "$1" >&2
  exit 1
}

# Run the script from the home directory
cd "$HOME"

# Ensure doas is installed
if ! command -v doas >/dev/null 2>&1; then
  error "'doas' is not installed. Please install it first."
fi

# Get the current username
USERNAME=$(whoami)

# Check for SSH key setup
info "Verifying SSH key setup..."
if [ ! -d "$HOME/.ssh" ]; then
  error "Directory ~/.ssh does not exist. Please create it and add your public keys before running this script."
fi

if [ ! -f "$HOME/.ssh/authorized_keys" ]; then
  error "File ~/.ssh/authorized_keys does not exist. Please create it and add your public keys before running this script."
fi

# Backup existing configuration files
info "Backing up existing configuration files..."
[ -f ~/.shrc ] && cp ~/.shrc ~/.shrc.backup
[ -f /etc/ssh/sshd_config ] && doas cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
[ -f /boot/loader.conf ] && doas cp /boot/loader.conf /boot/loader.conf.backup
[ -f /usr/local/etc/doas.conf ] && doas cp /usr/local/etc/doas.conf /usr/local/etc/doas.conf.backup

# Configure doas.conf
info "Configuring doas..."
DOAS_CONF="/usr/local/etc/doas.conf"
DOAS_RULE="permit nopass setenv { -ENV PATH=\$PATH LANG=\$LANG LC_CTYPE=\$LC_CTYPE } :wheel"
if ! grep -Fxq "$DOAS_RULE" "$DOAS_CONF"; then
  doas sh -c "echo '$DOAS_RULE' > $DOAS_CONF"
fi

# Configure .shrc
info "Configuring .shrc..."
SHRC_CONFIG="\nexport TERM=\"xterm-256color\"\nalias d='ls -alFG'\nset -o vi"
if ! grep -Fq "export TERM=\"xterm-256color\"" ~/.shrc; then
  printf "%s" "$SHRC_CONFIG" >>~/.shrc
fi

# Configure sshd
info "Configuring sshd..."
SSHD_CONFIG="/etc/ssh/sshd_config"
if ! grep -Fq "PasswordAuthentication no" "$SSHD_CONFIG"; then
  doas sh -c "cat <<EOF >> $SSHD_CONFIG
PasswordAuthentication no
ChallengeResponseAuthentication no
PermitRootLogin no
Protocol 2
AllowUsers $USERNAME
EOF"
fi

# Set SSH-related permissions
info "Setting SSH-related permissions..."
chmod go-w "/home/$USERNAME"
chmod 700 "/home/$USERNAME/.ssh"
chmod 600 "/home/$USERNAME/.ssh/authorized_keys"

# Configure /boot/loader.conf
info "Configuring /boot/loader.conf..."
LOADER_CONF="/boot/loader.conf"
LOADER_CONFIG="\nautoboot_delay=\"-1\"\nbeastie_disable=\"YES\"\nloader_logo=\"none\""
if ! grep -Fq "autoboot_delay=\"-1\"" "$LOADER_CONF"; then
  doas sh -c "printf '%s' '$LOADER_CONFIG' >> $LOADER_CONF"
fi

# Reload SSH service to apply changes
info "Reloading sshd service..."
if doas service sshd reload; then
  info "sshd service reloaded successfully."
else
  info "sshd service reload failed. Attempting to restart..."
  doas service sshd restart
fi

# Update the system non-interactively
info "Updating the system..."

# Use 'yes' to automatically answer 'yes' to prompts
# Combine fetch and install to minimize prompts
# Suppress output except for errors
export ASSUME_ALWAYS_YES=YES
env PAGER=/bin/cat doas /usr/sbin/freebsd-update --not-running-from-cron fetch install
unset ASSUME_ALWAYS_YES

# Check if freebsd-update was successful
if [ $? -eq 0 ]; then
  info "System updated successfully."
else
  error "No updates available."
fi

# Final messages
info "Initial setup complete."
echo "Please reboot your system and run the following commands after rebooting:"
echo "  doas pkg upgrade -y"
echo "  doas zfs snapshot zroot/ROOT/default@initial-setup"
