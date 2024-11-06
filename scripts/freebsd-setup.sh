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

# Check if the script is run from the home directory
# if [ "$PWD" != "$HOME" ]; then
#     error "Please run this script from your home directory."
# fi
# Run the script from the home directory
cd $HOME

# Ensure doas is installed
if ! command -v doas >/dev/null 2>&1; then
  error "'doas' is not installed. Please install it first."
fi

# Get the current username
USERNAME=$(whoami)

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
chmod go-w /home/$USERNAME
chmod 700 /home/$USERNAME/.ssh
chmod 600 /home/$USERNAME/.ssh/authorized_keys || true

# The `|| true` ensures the script doesn't exit if `authorized_keys` doesn't exist

# Configure /boot/loader.conf
info "Configuring /boot/loader.conf..."
doas sh -c "cat <<EOF >> /boot/loader.conf
autoboot_delay=\"-1\"
beastie_disable=\"YES\"
loader_logo=\"none\"
EOF"

# Update the system
info "Updating the system..."
doas freebsd-update fetch
doas freebsd-update install

# Final messages
info "Initial setup complete."
echo "Please reboot your system and run the following commands after rebooting:"
echo "  doas pkg upgrade -y"
echo "  doas zfs snapshot zroot/ROOT/default@initial-setup"
