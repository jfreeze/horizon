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
