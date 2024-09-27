#!/bin/bash

# ==============================
# Configuration
# ==============================
APP_NAME="fbsd_deploy" # Replace with your application's name
TARGET_DIR="/usr/local/$APP_NAME"
BUILD_MACHINE_USER="jimfreeze"                                            # Replace with your build machine username
BUILD_MACHINE_HOST="192.168.100.176"                                      # Replace with your build machine hostname or IP
REPO_DIR="/Users/jimfreeze/Documents/PARA/Projects/dev/freebsd-installer" # Ensure no trailing space

# Default deployment method
DEPLOY_METHOD="auto" # Options: auto, rsync, tar
FORCE_DEPLOY=0       # 0 = do not force, 1 = force deployment with uncommitted changes

# ==============================
# Functions
# ==============================

# Function to display usage
usage() {
  echo "Usage: $0 [--rsync | --tar] [--force]"
  exit 1
}

# Function to get the current commit hash
get_commit_hash() {
  git -C "$REPO_DIR" rev-parse HEAD
}

# Function to check for uncommitted changes
check_uncommitted_changes() {
  if ! git -C "$REPO_DIR" diff-index --quiet HEAD --; then
    if [ "$FORCE_DEPLOY" -eq 1 ]; then
      echo "Warning: You have uncommitted changes. Proceeding with deployment."
    else
      echo "Error: You have uncommitted changes. Please commit or stash them before deploying."
      exit 1
    fi
  fi
}

# Function to deploy files using rsync
deploy_rsync() {
  echo "Deploying using rsync..."
  rsync -avz --delete \
    --exclude='.git' \
    --exclude='*.tmp' \  # Add any other patterns to exclude
  "$REPO_DIR/$BUILD_MACHINE_USER@$BUILD_MACHINE_HOST:$TARGET_DIR/"
}

# Function to deploy files using tar and scp
deploy_tar_scp() {
  echo "Deploying using tar and scp..."
  # Create a temporary tarball excluding the .git directory and other unwanted files
  TAR_FILE=$(mktemp /tmp/deploy.XXXXXX.tar.gz)
  tar --exclude='.git' --exclude='*.tmp' -czf "$TAR_FILE" -C "$REPO_DIR" .

  # Transfer the tarball to the build machine
  scp -X "$TAR_FILE" "$BUILD_MACHINE_USER@$BUILD_MACHINE_HOST:/tmp/deploy.tar.gz"

  # Extract the tarball on the build machine
  ssh "$BUILD_MACHINE_USER@$BUILD_MACHINE_HOST" "
        doas mkdir -p $TARGET_DIR &&
        doas tar -xzf /tmp/deploy.tar.gz -C $TARGET_DIR &&
        doas rm /tmp/deploy.tar.gz
    "

  # Transfer the commit hash for verification with doas
  echo "$COMMIT_HASH" | ssh "$BUILD_MACHINE_USER@$BUILD_MACHINE_HOST" "doas mkdir -p $TARGET_DIR && doas tee $TARGET_DIR/COMMIT_HASH > /dev/null"

  # Remove the temporary tarball locally
  rm "$TAR_FILE"
}

# Function to verify deployment
verify_deployment() {
  REMOTE_COMMIT_HASH=$(ssh "$BUILD_MACHINE_USER@$BUILD_MACHINE_HOST" "cat $TARGET_DIR/COMMIT_HASH 2>/dev/null")
  if [ "$COMMIT_HASH" == "$REMOTE_COMMIT_HASH" ]; then
    echo "Deployment verified: Commit hash matches."
  else
    echo "Warning: Commit hash does not match. Deployment may be incomplete."
  fi
}

# Function to deploy using the selected method
deploy_files() {
  case "$DEPLOY_METHOD" in
  rsync)
    deploy_rsync
    ;;
  tar)
    deploy_tar_scp
    ;;
  auto)
    if command -v rsync >/dev/null 2>&1; then
      deploy_rsync
    else
      echo "rsync not found. Falling back to tar and scp."
      deploy_tar_scp
    fi
    ;;
  *)
    echo "Invalid deployment method: $DEPLOY_METHOD"
    exit 1
    ;;
  esac
}

# ==============================
# Parse Command-Line Arguments
# ==============================
while [[ $# -gt 0 ]]; do
  case "$1" in
  --rsync)
    DEPLOY_METHOD="rsync"
    shift
    ;;
  --tar)
    DEPLOY_METHOD="tar"
    shift
    ;;
  --force)
    FORCE_DEPLOY=1
    shift
    ;;
  -h | --help)
    usage
    ;;
  *)
    echo "Unknown option: $1"
    usage
    ;;
  esac
done

# ==============================
# Main Deployment Steps
# ==============================

echo "Starting deployment process..."

# Navigate to the repository directory
cd "$REPO_DIR" || {
  echo "Repository directory not found!"
  exit 1
}

# Check for uncommitted changes
check_uncommitted_changes

# Get the current commit hash
COMMIT_HASH=$(get_commit_hash)
echo "Current commit hash: $COMMIT_HASH"

# Deploy the files using the selected method
deploy_files

# Transfer the commit hash for verification (handled in deploy_rsync or deploy_tar_scp)
# If deploying via rsync, ensure the commit hash is transferred
if [ "$DEPLOY_METHOD" = "rsync" ] || [ "$DEPLOY_METHOD" = "auto" ]; then
  echo "$COMMIT_HASH" | ssh "$BUILD_MACHINE_USER@$BUILD_MACHINE_HOST" "doas mkdir -p $TARGET_DIR && doas tee $TARGET_DIR/COMMIT_HASH > /dev/null"
fi

# Verify the deployment
verify_deployment

echo "Deployment process completed."
