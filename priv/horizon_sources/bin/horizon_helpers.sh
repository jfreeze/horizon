#!/bin/sh

# Helper functions for Horizon

exit_if_not_root() {
  # Check if the current user is root (UID 0)
  if [ "$(id -u)" -ne 0 ]; then
    echo "Insufficient privileges. Please run this script as root. Exiting..."
    exit 1
  fi
}

get_arch() {
  # Retrieve the operating system name
  os=$(uname -s)

  # Map the OS name to the desired format
  case "$os" in
  FreeBSD)
    os_mapped="freebsd"
    ;;
  Linux)
    os_mapped="linux"
    ;;
  Darwin)
    os_mapped="macos"
    ;;
  *)
    echo "Unsupported OS: $os" >&2
    return 1
    ;;
  esac

  # Retrieve the machine architecture
  arch=$(uname -m)

  # Map the architecture to the desired format
  case "$arch" in
  amd64)
    arch_mapped="x64"
    ;;
  arm64)
    arch_mapped="arm64"
    ;;
  arm | armv7)
    arch_mapped="armv7"
    ;;
  *)
    echo "Unsupported architecture: $arch" >&2
    return 1
    ;;
  esac

  # Combine and return the mapped OS and architecture
  echo "${os_mapped}-${arch_mapped}"
}

#
# Function: update_path
#
# Description:
#
#   Updates the PATH environment variable by adding the binary path of specified packages.
#   The update is also appended to the .shrc file to persist across sessions.
#   Supports both exact and partial package name matching.
#
# Usage:
#   update_path package_name1 package_name2 ...
#
# ## Example:
#
# update_path erlang-runtime27-27.0
#
# To use the function in your shell, source this script or include it in your .shrc
#

update_path() {
  # Define the shell RC file (modify if using a different shell)
  RC_FILE="$HOME/.shrc"

  # Ensure the RC file exists; create it if it doesn't
  if [ ! -f "$RC_FILE" ]; then
    touch "$RC_FILE" || {
      echo "❌  Failed to create $RC_FILE"
      return 1
    }
  fi

  # Iterate over all provided package names
  for input_pkg in "$@"; do
    path=""

    # Check if the exact package exists
    exact_match=$(pkg info | awk -v pkg="$input_pkg" '$1 == pkg {print $1}')

    if [ -n "$exact_match" ]; then
      selected_pkg="$exact_match"
      echo "🔍  Found exact match: $selected_pkg"
    else
      # If no exact match, treat input as partial and find matching packages
      matching_pkgs=$(pkg info | awk -v prefix="$input_pkg" '$1 ~ "^"prefix {print $1}')

      if [ -z "$matching_pkgs" ]; then
        echo "⚠️  No installed packages match: $input_pkg"
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
        echo "⚠️  No valid numeric version found for partial package: $input_pkg"
        continue
      fi

      echo "🔍  Selected package based on partial match: $selected_pkg"
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
        echo "⚠️  No extraction logic defined for package: $selected_pkg"
        continue
        ;;
      esac

      # Check if the path was successfully extracted
      if [ -n "$path" ]; then
        # Trim leading and trailing whitespace from the path
        trimmed_path=$(printf '%s' "$path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Verify that trimming was successful and path is not empty
        if [ -z "$trimmed_path" ]; then
          echo "❌  Extracted path is empty after trimming for package: $selected_pkg"
          continue
        fi

        # Check if the trimmed path is already in the current PATH
        echo "$PATH" | tr ':' '\n' | grep -Fxq "$trimmed_path"
        if [ $? -ne 0 ]; then
          # Prepend the new path to PATH
          export PATH="$trimmed_path:$PATH"
          echo "✅  Updated PATH with: $trimmed_path"
        else
          echo "🔍  Path already exists in PATH: $trimmed_path"
        fi

        # Prepare the export line for the RC file
        export_line="export PATH=\"$trimmed_path:\$PATH\""

        # Check if the export line already exists in the RC file
        grep -Fxq "$export_line" "$RC_FILE"
        if [ $? -ne 0 ]; then
          # Append the export line to the RC file
          echo "$export_line" >>"$RC_FILE" &&
            echo "📝  Added PATH update to $RC_FILE"
        else
          echo "🔍  PATH update already exists in $RC_FILE"
        fi
      else
        echo "❌  Failed to extract path for package: $selected_pkg"
      fi
    else
      echo "❌  No package selected for input: $input_pkg"
    fi
  done
}

add_user() {
  username="$1"

  exit_if_not_root

  # Check if the user exists
  if id "$username" >/dev/null 2>&1; then
    echo "User '$username' already exists."
  else
    # Add the user with nologin shell
    echo "Adding user..."
    pw user add -n <%= @app %> -c 'Service user for <%= @app %>' -s /usr/sbin/nologin

    if [ $? -eq 0 ]; then
      echo "User '$username' added successfully."
    else
      echo "Failed to add user '$username'."
    fi
  fi
}
