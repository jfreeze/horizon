```conf
#
# Horizon.Ops - Sample Config for a build host
#

# The `pkg` option installs the specified package using the package manager.
pkg:ca_root_nss
pkg:gcc
pkg:rsync
pkg:gmake
pkg:git
pkg:erlang-runtime27

# For Tailwind v4
pkg:npm-node23

# The `path` option sets a runtime path for the script
# Set the path to erlang so we can install elixir
path:/usr/local/lib/erlang27/bin

# The `elixir` option pulls the specified version of Elixir from github and builds Elixir from source
elixir:1.18.2
```
