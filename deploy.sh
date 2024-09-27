#!/bin/bash -e

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
# Color Definitions
# ==============================
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ==============================
# Functions
# ==============================

# Function to display usage
usage() {
  echo -e "${GREEN}Usage: $0 [--rsync | --tar] [--force]${NC}"
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
      echo -e "${RED}Warning: You have uncommitted changes. Proceeding with deployment.${NC}"
    else
      echo -e "${RED}Error: You have uncommitted changes. Please commit or stash them before deploying.${NC}"
      exit 1
    fi
  fi
}

# Function to compute a hash of the local directory
compute_local_hash() {
  echo -e "${GREEN}Computing local deployment hash...${NC}" >&2

  # Change to the repository directory
  cd "$REPO_DIR" || {
    echo -e "${RED}Error: Repository directory not found!${NC}" >&2
    exit 1
  }

  # Find all files, sort them, compute SHA256 hashes, and aggregate them
  # Excluding .git and other unwanted files
  find . -type f ! -path "./.git/*" ! -name "*.tmp" -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256 | awk '{print $1}'
}
# Function to compute a hash of the remote directory
compute_remote_hash() {
  echo -e "${GREEN}Computing remote deployment hash...${NC}" >&2

  ssh "$BUILD_MACHINE_USER@$BUILD_MACHINE_HOST" "cd \"$TARGET_DIR\" && find . -type f ! -path \"./.git/*\" ! -name \"*.tmp\" -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256 | awk '{print \$1}'"
}

# Function to deploy files using rsync with checksum verification
deploy_rsync() {
  echo -e "${GREEN}Deploying using rsync with checksum verification...${NC}"
  rsync -avzc --delete \
    --rsync-path="doas rsync" \
    --exclude='.git' \
    --exclude='*.tmp' \
    "$REPO_DIR/" \
    "$BUILD_MACHINE_USER@$BUILD_MACHINE_HOST:$TARGET_DIR/"

  if [ $? -ne 0 ]; then
    echo -e "${RED}Error: rsync failed.${NC}" >&2
    exit 1
  fi
}

# Function to deploy files using tar and scp
deploy_tar_scp() {
  echo -e "${GREEN}Deploying using tar and scp...${NC}"

  # Create a unique temporary directory
  TEMP_DIR=$(mktemp -d /tmp/deploy.XXXXXX)
  if [ ! -d "$TEMP_DIR" ]; then
    echo -e "${RED}Error: Failed to create temporary directory.${NC}"
    exit 1
  fi

  # Define the tarball path
  TAR_FILE="$TEMP_DIR/deploy.tar.gz"

  # Create the tarball excluding the .git directory and other unwanted files
  tar --exclude='.git' --exclude='*.tmp' -czf "$TAR_FILE" -C "$REPO_DIR" .

  if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to create tarball.${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  # Transfer the tarball to the build machine
  scp "$TAR_FILE" "$BUILD_MACHINE_USER@$BUILD_MACHINE_HOST:/tmp/deploy.tar.gz"
  if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to transfer tarball via scp.${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  # Extract the tarball on the build machine
  ssh "$BUILD_MACHINE_USER@$BUILD_MACHINE_HOST" "
    doas mkdir -p $TARGET_DIR &&
    doas tar -xzf /tmp/deploy.tar.gz -C $TARGET_DIR &&
    doas rm /tmp/deploy.tar.gz
  "
  if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to extract tarball on the build machine.${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  # Remove the temporary tarball locally
  rm -rf "$TEMP_DIR"
}

verify() {
  case "$DEPLOY_METHOD" in
  tar)
    verify_deployment
    ;;
  *)
    echo -e "Using rsync checksum for verification"
    ;;
  esac
}

# Function to verify deployment integrity by comparing hashes
verify_deployment() {
  echo -e "${GREEN}Verifying deployment integrity...${NC}"

  LOCAL_HASH=$(compute_local_hash)
  REMOTE_HASH=$(compute_remote_hash)

  echo -e "${GREEN}Local deployment hash: $LOCAL_HASH${NC}"
  echo -e "${GREEN}Remote deployment hash: $REMOTE_HASH${NC}"

  if [ "$LOCAL_HASH" == "$REMOTE_HASH" ]; then
    echo -e "${GREEN}Deployment verified: Deployment hashes match.${NC}"
  else
    echo -e "${RED}Warning: Deployment hashes do not match. Deployment may be incomplete or corrupted.${NC}"
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
      echo -e "${RED}rsync not found. Falling back to tar and scp.${NC}"
      deploy_tar_scp
    fi
    ;;
  *)
    echo -e "${RED}Invalid deployment method: $DEPLOY_METHOD${NC}"
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
    echo -e "${RED}Unknown option: $1${NC}"
    usage
    ;;
  esac
done

# ==============================
# Main Deployment Steps
# ==============================

echo -e "${GREEN}Starting deployment process...${NC}"

# Navigate to the repository directory
cd "$REPO_DIR" || {
  echo -e "${RED}Error: Repository directory not found!${NC}"
  exit 1
}

# Check for uncommitted changes
check_uncommitted_changes

# Get the current commit hash
COMMIT_HASH=$(get_commit_hash)
echo -e "${GREEN}Current commit hash: $COMMIT_HASH${NC}"

# Deploy the files using the selected method
deploy_files

# Verify the deployment
verify

echo -e "${GREEN}Deployment process completed.${NC}"
