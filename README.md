# Horizon


Welcome to **Horizon**, an Elixir project that is a toolbox for managing Phoenix deployments. It provides tools for FreeBSD host configuration and creating and deploying Elixir/Phoenix releases. 

No special tools are required for host configuration or release management other than SSH access to the host. (Release management is done through `/bin/sh` scripts but may require modification to work with Linux systems. PRs are welcome.)

The host configuration includes a `bsd_install.sh` script that facilitates installing FreeBSD packages, building Elixir from source, enabling and starting services, installing and configuring PostgreSQL, and creating databases.

Release management involves **three steps**: 1) **staging** of the source code to the build server, 2) **building** the release tarball on the build server, and 3) **deploying** a tarball to the deploy server and starting the application service.

```mermaid
graph LR
    A[Horizon.init] --> B[STAGE]
    B --> C[BUILD]
    C --> D[DEPLOY]
```

In addition to easy host management and rapid deployments, Horizon was motivated to help facilitate Phoenix deployments for platforms other than your development platform, e.g., MacOS -> FreeBSD.
## Installation

(TBD) Add `horizon` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:horizon, "~> 0.1.0", runtime: false}
  ]
end
```

## Add a Release to mix.exs

Horizon requires a `release` to be defined in `mix.exs`. 
```elixir
      my_app: [
        applications: [runtime_tools: :permanent],
        include_executables_for: [:unix],
        build_user: System.get_env("BUILD_USER"),
        build_host: System.get_env("BUILD_HOST"),
        deploy_host: System.get_env("DEPLOY_HOST"),
        deploy_user: System.get_env("DEPLOY_USER"),
        # releases_path: ".releases",
        # bin_path: "bin",
        # build_path: "/usr/local/opt/my_app/build",
        # app_path: "/usr/local/my_app",
        # release_commands: [],
        steps: [
          &Horizon.Step.setup/1,
          :assemble,
          :tar
        ]
      ],
```

Running `mix horizon.init` creates scripts for each `release`. FreeBSD customary defaults are used for installation paths and are added when you include `&Horizon.Step.setup/1` as the first step of each release.

Note: `assemble` is required to create your release target. `tar` is required to build a tarball for deployment.

## Env vars

Running `mix release.init` creates a `rel/` directory that contains the file `env.sh.eex`. You can add env vars there directly or, if you are using a `.env` file for environment variables, you can reference that file from within your `env.sh.eex` file.

```shell
dir="$(cd "$(dirname "$0")" && pwd)"
env_file=$(cd "$dir/../../my_app/" && pwd)/.env
chmod 600 $env_file
```

You will need to add `.env` to your deploy artifacts. One solution is to copy the .env file to your `overlays` folder in `rel/overlays/.env`.

## Deploying with Horizon

To deploy your Elixir/Phoenix app, create your `Horizon` helper scripts with

```shell
mix horizon.init
```

**Note, you will need to run `horizon.init` to update your scripts every time you make a change to a `release` in `mix.exs`.**

Note, that you can have a different `bin` folder for each release. 

Assuming you have used the default `bin` folder for your project, the release steps would look like:

```shell
# transfer existing code state to build server
./bin/stage-my_app.sh --force

# build your app on the build server and 
# copy the tarball to .releases/
./bin/build-my_app.sh

# deploy the release
./bin/deploy-my_app.sh
```

That's it.

Note: Due to your beam application being a script and not a binary executable, stopping an app that was started using the default Elixir release code will timeout. `Horizon` fixes this by creating a run command file in `/usr/local/etc/rc.d/my_app`. On FreeBSD, the default script for running **`remote`** or **`eval`** is fine, but for starting/stopping the service, you should use:

```shell
# service my_app start|stop|restart|status
```

Default script usage (`eval`, `rpc`, `remote` ok to use):
```
Usage: my_app COMMAND [ARGS]

The known commands are:

    start          Starts the system
    start_iex      Starts the system with IEx attached
    daemon         Starts the system as a daemon
    daemon_iex     Starts the system as a daemon with IEx attached
    eval "EXPR"    Executes the given expression on a new, non-booted system
    rpc "EXPR"     Executes the given expression remotely on the running system
    remote         Connects to the running system via a remote shell
    restart        Restarts the running system via a remote command
    stop           Stops the running system via a remote command
    pid            Prints the operating system PID of the running system via a remote command
    version        Prints the release name and version to be booted
```

## Host Configuration

The above deployment example assumes you have a running build host, deployment host, and database host. If you don't, never fear. `Horizon` can help you build these in a matter of minutes.

The sample configuration files were used on a FreeBSD 14.1 base install. The only requirements for the base install by `Horizon` are that they have `doas` installed and configured.

```shell
# pkg install -y doas
doas echo "permit nopass setenv { -ENV PATH=$PATH LANG=$LANG LC_CTYPE=$LC_CTYPE } :wheel" > /usr/local/etc/doas.conf
```

### Sample Build Host Configuration
This is a sample configuration file for a build host.  The only expectation for this host is that it needs to build a release, but not run the application.

`#build.conf`
```
#
# Setup for an Elixir/Pheonix FreeBSD build host
#

pkg:ca_root_nss
pkg:gcc
pkg:gmake
pkg:git
pkg:rsync
pkg:erlang-runtime27

# Store the path to erlang for builds
dot-path:/usr/local/lib/erlang27/bin

# Set the path to erlang so we can install elixir
path:/usr/local/lib/erlang27/bin

elixir:1.17.3
```

To install this script run:

```
./bin/bsd_install.sh -u me target_host build.conf
```
### Sample Web Host Configuration
A web host has minimal configuration because we ship the erlang runtime in the deployments. This allows you to update the Elixir version on deployments.

This example assumes the app needs `vips` for use with `vix`. (not tested.)

`#web.conf`
```
pkg:vips
```

Install with:

```
./bin/bsd_install.sh -u me target_host web.conf
```
### Sample Postgres Host Configuration
It's a good idea to keep your Postgres server on a separate server. This allows it to have its own upgrade process and simplifies mirroring and migration. Although, you could install Postgres on the same host as the web host, and even on the build host.

There are three steps to getting Postgres up and running:
1. Install the version of postgres server and contrib library of your choice
2. Initialize postgresql. This configures `postgresql.conf`, `pg_hba.conf` and logging. Logging is at `/var/log/postgresql.go`
3. Create a database. Creating a database creates a user/password, and updates `pg_hba.conf`. You can also choose the locale and `ctype` of the database.
	- postgres-db-c_mixed_utf8
	- postgres-db-c_utf8_full
	- postgres-db-us_utf8_full

`#postgres.conf`
```
pkg:postgresql16-server
pkg:postgresql16-contrib
postgres.init

postgres.db:c_mixed_utf8:mydb
```

Install with:

```
./bin/bsd_install.sh -u me target_host postgres.conf
```

With hosts configured, you can now build and deploy an Elixir app.

- Staging copies the app source to the build machine.
- Building creates a tarball that is ready to run on a deploy host.
- Deploy copies the tarball to the build machine and starts the service. (Future: JEDI can allows hot deploys to a running service.)

## Deploying an Elixir App



#### Deploy
put this above. note that app runs as app user.
copies the `rc_d` script to the host, creates user.
copies the tarball to the target host and starts the service.


[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---


