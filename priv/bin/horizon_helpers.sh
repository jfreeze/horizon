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

# Function: update_path
# Description:
#   Updates the PATH environment variable by adding the binary path of specified packages.
#   The update is also appended to the .shrc file to persist across sessions.
#   Supports partial package name matching (e.g., 'erlang-runtime' matches 'erlang-runtime27', 'erlang-runtime28', etc.)
# Usage:
#   update_path partial_package_name1 partial_package_name2 ...

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

  # Iterate over all provided partial package names
  for partial_pkg in "$@"; do
    # Find all installed packages matching the partial name
    matching_pkgs=$(pkg info | awk -v prefix="$partial_pkg" '$1 ~ "^"prefix {print $1}')

    if [ -z "$matching_pkgs" ]; then
      echo "⚠️  No installed packages match: $partial_pkg"
      continue
    fi

    # Select the latest version by sorting numerically and picking the last one
    selected_pkg=$(echo "$matching_pkgs" | sort -V | tail -n 1)

    echo "🔍  Selected package: $selected_pkg"

    path=""

    case "$partial_pkg" in
    erlang-runtime*)
      # Method 1: Parse pkg info -D output to find the binary path
      path=$(pkg info -D "$selected_pkg" 2>/dev/null |
        grep 'binary path' |
        sed -n 's/.*binary path ["'\'']\([^"\'']*\)["'\''].*/\1/p')

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

    # Add additional partial package cases here
    # Example:
    # another-pkg*)
    #     # Extraction logic for another-pkg
    #     ;;

    *)
      echo "⚠️  No extraction logic defined for partial package: $partial_pkg"
      continue
      ;;
    esac

    # Check if the path was successfully extracted
    if [ -n "$path" ]; then
      # Check if the path is already in the current PATH
      echo "$PATH" | tr ':' '\n' | grep -Fxq "$path"
      if [ $? -ne 0 ]; then
        # Prepend the new path to PATH
        export PATH="$path:$PATH"
        echo "✅  Updated PATH with: $path"
      else
        echo "🔍  Path already exists in PATH: $path"
      fi

      # Prepare the export line for the RC file
      export_line="export PATH=\"$path:\$PATH\""

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
  done
}

# Example Usage:
# Uncomment the following line to test the function with 'erlang-runtime'
# update_path erlang-runtime

# To use the function in your shell, source this script or include it in your .shrc
