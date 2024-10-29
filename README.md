# Horizon

Welcome to **Horizon**, an Ops library for deploying Elixir/Phoenix
projects. Horizon lets you stage, build, and deploy your Elixir/Phoenix
app in minutes. Horizon also has tools for standing up a Postgres server
with continual backups and drive replication via `zfs` snapshots. 

Full control of your ops environment is at your fingertips. 

With the Power to Serve, Horizon's first ops platform is FreeBSD.

No special tools are required for host configuration or release management
other than SSH access to the host. (Release management is done through `/bin/sh` scripts.

The BSD host configuration includes a `bsd_install.sh` script that facilitates installing FreeBSD packages, building Elixir from source, enabling and starting services, installing and configuring PostgreSQL, and creating databases.

Release management involves **three steps**:
** staging** of the source code to the build server
** building** the release tarball on the build server
** deploying** a tarball to the deploy server and starting the application service

```mermaid
graph LR
 A[Horizon.Ops.BSD.init] --> B[STAGE]
 B --> C[BUILD]
 C --> D[DEPLOY]
```

In addition to easy host management and rapid deployments, Horizon.Ops was motivated to help facilitate Phoenix deployments for platforms other than your development platform, e.g., MacOS -> FreeBSD or MacOS -> Linux.

## Installation

(TBD) Add `horizon` to your list of dependencies in `mix.exs`:

```elixir
def deps do
 [
    {:horizon, "~> 0.1.2", runtime: false}
 ]
end
```

### Add a Release to your mix.exs

Horizon.Ops requires a `release` to be defined in `mix.exs`. 
```elixir
  def project do
    [
      app: :my_app,
      ...,
      releases: [
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
            &Horizon.Ops.BSD.Step.setup/1,
            :assemble,
            :tar
          ],
          # cookie: System.fetch_env("RELEASE_COOKIE")
        ]
      ]
    end
```

Running `mix horizon.bsd.init` creates scripts for each `release`. FreeBSD customary defaults are used for installation paths and are added when you include `&Horizon.Ops.BSD.Step.setup/1` as the first step of each release.

Note: `assemble` is required to create your release target. `tar` is needed to build a tarball for deployment.

### Tailwind

A typical `assets.setup` looks like:

```
"assets.setup": [
   "tailwind.install --if-missing",
   "esbuild.install --if-missing"
],
```

However, since a tailwind download for FreeBSD is not currently provided by the Tailwind project, the `tailwind.install` supports passing a URL from which to download the app. 

Add the following to your `mix.exs` file.

```
@tailwindcss_freebsd_x64 "https://people.freebsd.org/~dch/pub/tailwind/v$version/tailwindcss-$target"

...
defp aliases do
  [
    ...
    "assets.setup.freebsd": [
      "tailwind.install #{@tailwindcss_freebsd_x64}",
      "esbuild.install --if-missing"
    ],
    ...
  ]
end
```

### Env vars

Running `mix release.init` creates a `rel/` directory that contains the file `env.sh.eex`. The simplest way to manage env vars is to add them directly to `env.sh.eex`:

```
...
export SECRET_KEY_BASE=5HPxy5qOJ...
export PHX_SERVER=true
...
```

If you are using a `.env` file for environment variables, one method is just to add it to your `env.sh.eex` file:

```
cat .env >> rel/env.sh.eex
```

Or, you can reference the `.env` file from within your `env.sh.eex` file.

```shell
env_file=/usr/local/my_app/.env
chmod 600 $env_file
. $env_file
```

You will need to add `.env` to your deploy artifacts. One solution is to copy the .env file to your `overlays` folder in `rel/overlays/.env`.

However, this method may be insufficient since it would be the same `.env` file for all deploys. Writing a `Step` or a more sophisticated overlay that is version dependent may be required if not using `env.sh.eex`.

## Deploying with Horizon.Ops

To deploy your Elixir/Phoenix app, create your `Horizon.Ops` helper scripts with

```shell
mix horizon.bsd.init
```

**Note, you must run `horizon.bsd.init` to update your scripts every time you change `release` in `mix.exs`.**

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

If you need to deploy to multiple hosts, you can specify the user and host with the `-u` and `-h` options:

```
./bin/deploy-my_app.sh -u me -h example.com
```

Note: Since your beam application is a script and not a binary executable, stopping an app that started using the default Elixir release code will timeout. `Horizon.Ops` fixes this by creating a run command file in `/usr/local/etc/rc.d/my_app`. On FreeBSD, the default script for running **`remote`** or **`eval`** is fine, but for starting/stopping the service, you should use:

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

The above deployment example assumes you have a running build, deployment, and database host. If you don't, never fear. `Horizon.Ops` can help you build these in minutes.

The sample configuration files were used on a FreeBSD 14.1 base install. The only requirements for the base installation by Horizon.Ops are that they have `doas` installed and configured.

```shell
# pkg install -y doas
doas echo "permit nopass setenv { -ENV PATH=$PATH LANG=$LANG LC_CTYPE=$LC_CTYPE } :wheel" > /usr/local/etc/doas.conf
```

### Sample Build Host Configuration

This is a sample configuration file for a build host.  The only expectation for this host is to build a release but not run the application.

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

A web host has minimal configuration because we ship the Erlang runtime in the deployments. This allows you to update the Elixir version on deployments.

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

Keeping your Postgres server on a separate server is a good idea. This allows it to have its own upgrade process and simplifies mirroring and migration. You can install Postgres on the same host as the web host and even on the build host.

There are three steps to getting Postgres up and running:

1. Install the version of postgres server and contrib library of your choice
2. Initialize `postgresql`. This configures `postgresql.conf`, `pg_hba.conf` and logging. Logging is at `/var/log/postgresql.log`
3. Create a database. Creating a database creates a user/password, and updates `pg_hba.conf`. You can also choose the locale and `ctype` of the database.
- postgres-db-c_mixed_utf8
- postgres-db-c_utf8_full
- postgres-db-us_utf8_full

`#postgres.conf`
```
pkg:postgresql16-server
pkg:postgresql16-contrib
postgres.init

# Encode with UTF8 and sort with byte order
postgres.db:c_mixed_utf8:mydb

# Other postgresql options
#postgres.db:us_utf8_full:mydb
#postgres.db:c_utf8_full:mydb
```

Install with:

```
./bin/bsd_install.sh -u me target_host postgres.conf
```

With hosts configured, you can now build and deploy an Elixir app.

- Staging copies the app source to the build machine.
- Building creates a tarball that is ready to run on a deploy host.
- Deploy copies the tarball to the build machine and starts the service. (Future: JEDI can allow hot deploys to a running service.)

## Horizon.Ops.BSD Release Steps in Detail

Here is a summary of the actions taken in each release step.

### Stage
- Uses `rsync` or `tar/scp` to copy the current project state to the build host
### Build
- checks if `tailwind` is available and downloads it if needed.
- installs `mix local.hex`
- runs `mix deps.get`
- runs `mix assets.setup.freebsd`
- runs `mix phx.digest.clean --all`
- runs `mix assets.deploy`
- runs `mix release`
  - Calls `Horizon.Ops.BSD.Step.setup/1` that creates the rcd script
- stores the tarball in .releases
- stores the tarball name in `.releases/my_app.data`
### Deploy

- adds `my_app_enable="YES"` to `/etc/rc.conf`
- expands the tarball
- sets `env.sh` to mode 0400.
- creates user 'my_app' if it doesn't exist
- moves rcd script to `/usr/local/etc/rc.d/my_app`
- runs any optional release commands
- runs `doas service my_app restart`

Apps are started with the user that has the same name as the app.
For example, the release `my_app` will be run as the user `my_app`.
This allows multiple Elixir/Phoenix apps to reside on the same
server, each isolated from the other and individually controlled
with the `service` command.

Source code is licensed under the [BSD 3-Clause License](LICENSE.md).

---


