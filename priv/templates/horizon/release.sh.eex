#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Set the Mix environment to production
export MIX_ENV=prod

# Define paths (adjust if your project structure differs)
APP_DIR=$(cd "$(dirname "$0")/.." && pwd)

# Navigate to the project directory
cd "$APP_DIR"

echo "=== Starting Release Process ==="

# Step 1: Setup Assets
echo "--- Setting up assets ---"
mix assets.setup

# Step 2: Clean Existing Digests
echo "--- Cleaning existing digests ---"
mix phx.digest.clean --all

# Step 3: Deploy Assets
echo "--- Deploying assets ---"
mix assets.deploy

# Step 4: Create/Update Release
echo "--- Creating/updating the release ---"
mix release --overwrite

# Step 5: Restart the Server
echo "--- Restarting the server ---"
doas server app restart

echo "=== Release Process Completed Successfully ==="
