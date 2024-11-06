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

# Function to prompt for user confirmation
confirm() {
  printf "\033[1;33m[WARNING]\033[0m %s [y/N]: " "$1"
  read response
  case "$response" in
  [yY][eE][sS] | [yY])
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

# Run the script from the home directory
cd $HOME

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
doas cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
doas cp /boot/loader.conf /boot/loader.conf.backup

# Configure .shrc
info "Configuring .shrc..."
cat <<EOF >>~/.shrc

export TERM="xterm-256color"
alias d='ls -alFG'
set -o vi
EOF

# Configure sshd
info "Configuring sshd..."
doas sh -c "cat <<EOF >> /etc/ssh/sshd_config
PasswordAuthentication no
ChallengeResponseAuthentication no
PermitRootLogin no
Protocol 2
AllowUsers $USERNAME
EOF"

# Set SSH-related permissions
info "Setting SSH-related permissions..."
chmod go-w "/home/$USERNAME"
chmod 700 "/home/$USERNAME/.ssh"
chmod 600 "/home/$USERNAME/.ssh/authorized_keys"

# Configure /boot/loader.conf
info "Configuring /boot/loader.conf..."
doas sh -c "cat <<EOF >> /boot/loader.conf
autoboot_delay=\"-1\"
beastie_disable=\"YES\"
loader_logo=\"none\"
EOF"

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
yes | doas freebsd-update fetch install >/dev/null 2>&1

# Check if freebsd-update was successful
if [ $? -eq 0 ]; then
  info "System updated successfully."
else
  error "System update failed. Please run 'freebsd-update fetch install' manually."
fi

# Final messages
info "Initial setup complete."
echo "Please reboot your system and run the following commands after rebooting:"
echo "  doas pkg upgrade -y"
echo "  doas zfs snapshot zroot/ROOT/default@initial-setup"
