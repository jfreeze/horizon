# Horizon

Welcome to **Horizon**, an ops library for **deploying Elixir/Phoenix
projects** to FreeBSD hosts. 

## Features
- Only SSH access is required for administration
- Uses install files so you can version manage host configuration
- Installs Elixir, Erlang, Postgres and Postgres databases
- Full Postgres install with a single command
- Tools to setup Postgres backup server
- Simplifies FreeBSD management on ZFS file systems
- Can deploy to bare-metal or VM hosts

## Getting Started

This guide is intended to help you get started with Horizon for deploying your Elixir/Phoenix application to FreeBSD hosts.
Follow the installation instructions on this page to configure your existing project to use Horizon for deployment.

Then follow the guides below to setup your host servers and deploy your Elixir/Phoenix application with Horizon.

- [Deploying with Horizon](../doc/deploying-with-horizon.html)
- [Horizon Ops Scripts](../doc/horizon-helper-scripts.html)
- [Sample Host Configurations](../doc/sample-host-configurations.html)
- [Proxy Configuration](../doc/proxy-conf.html)


### Additional Guides and Resources
- [FreeBSD Template Setup](../doc/freebsd-template-setup.html)
- [Hetzner Cloud Setup Guide](../doc/hetzner-cloud.html)
- [Hetzner Cloud Host Instantiation](../doc/hetzner-cloud-host-instantiation.html)
- [FreeBSD Installation](../doc/freebsd-install.html)
- [Creating a FreeBSD VM on Proxmox](../doc/proxmox.html)

## Installation

Add `horizon` to your list of dependencies in `mix.exs`:

```elixir
def deps do
 [
    {:horizon, "~> 0.1.3", runtime: false}
 ]
end
```

After adding `horizon` to your list of dependencies, run:

```shell
mix deps.get
```

Use the following instructions to configure your application so Horizon can 
`stage`, `build` and `deploy` your applications.

- [Define a Release in `mix.exs`](#configuring-your-project-for-horizon)
- [Add Tailwind to your `assets.setup`](#configuring-tailwind-for-freebsd)
- [Run `mix horizon.init`](#running-mix-horizon-init)

## Configuring your project for Horizon

Horizon builds scripts for each release in your project to `stage`, `build`, and `deploy` your Elixir/Phoenix app.

If you haven't defined a release, add one to your `mix.exs` file. 

The simplest release configuration looks like:
```elixir
  def project do
    [
      app: :my_app,
      ...,
      releases: [my_app: []]
      ...
    ]
  end
```

In general however, you will want configure access information for your build and deploy hosts.
The example below also configures [steps](https://hexdocs.pm/mix/Mix.Tasks.Release.html#module-steps) 
to set the [default release values for a FreeBSD system
and to create the run control script](Horizon.Ops.BSD.Step.html) in the `rel/overlays/rc_d/` folder. 


```elixir
  def project do
    [
      app: :my_app,
      ...,
      releases: [
        my_app: [
          applications: [runtime_tools: :permanent],
          include_executables_for: [:unix],
          build_host_ssh: System.get_env("BUILD_HOST_SSH"),
          deploy_hosts_ssh: System.get_env("DEPLOY_HOSTS_SSH"),
          # app_path: "/usr/local/my_app",
          # bin_path: "bin",
          # build_path: "/usr/local/opt/my_app/build",
          # release_commands: [],
          # releases_path: ".releases",
          steps: [
            &Horizon.Ops.BSD.Step.setup/1,
            :assemble,
            :tar
          ],
        ]
      ]
    end
```
> `assemble` is required to create your release target. `tar` is needed to build a tarball for deployment.

## Configuring Tailwind for FreeBSD

The default mix alias `assets.setup` is:

```
"assets.setup": [
   "tailwind.install --if-missing",
   "esbuild.install --if-missing"
],
```

However, a tailwind download for FreeBSD is not currently provided by the Tailwind project.
This is resolved by passing a URL to `tailwind.install` from which to download the tailwind executable.

**Add the `"assets.setup.freebsd"` mix alias to your `mix.exs` file.**

```
@tailwindcss_freebsd_x64 "https://people.freebsd.org/~dch/pub/tailwind/v$version/tailwindcss-$target"

...
defp aliases do
  [
    ...
    "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
    "assets.setup.freebsd": [
      "tailwind.install #{@tailwindcss_freebsd_x64}",
      "esbuild.install --if-missing"
    ],
    ...
  ]
end
```

## Horizon Script Generation

Running `mix horizon.init` creates scripts for each of the`releases` defined in your mix project. FreeBSD customary defaults are used for installation paths and are added when you include `&Horizon.Ops.BSD.Step.setup/1` as the first `step` of each release.

Running this script will provide instructions for creating a mix alias `"assets.setup.freebsd"` (if not already configured) that will install `esbuild` and `tailwind` on your build host.

```shell
❯ mix horizon.init
Created   bin/horizon_helpers.sh
Created   bin/stage-my_app1.sh
Created   bin/build-my_app1.sh
Created   bin/build_script-my_app1.sh
Created   bin/deploy-my_app1.sh
Created   bin/deploy_script-my_app1.sh
```

> **You must run `mix horizon.init` to update your scripts every time you change a `release` in `mix.exs`.**

## Configuring Env vars for releases

Running `mix release.init` creates a `rel/` directory that contains the file `env.sh.eex`. 
**The simplest way to manage env vars is to add them directly to `rel/env.sh.eex`:**

```
...
export SECRET_KEY_BASE=5HPxy5qOJ...
export PHX_SERVER=true
...
```

### Alternative: Importing existing `.env` file
If you are using a `.env` file for environment variables, one method is just to add it to your `env.sh.eex` file:

```
cat .env >> rel/env.sh.eex
```

Or, reference the `.env` file from within `env.sh.eex`.

```shell
env_file=/usr/local/my_app/.env
chmod 600 $env_file
. $env_file
```

If using this method, you will need to add `.env` to your deploy artifacts. 
One solution is to copy the .env file to your `overlays` folder in `rel/overlays/.env`.

> This method may be insufficient since the same `.env` file is shared for all deploy versions. 
Writing a [`step`](https://hexdocs.pm/mix/Mix.Tasks.Release.html#module-steps) or a more sophisticated overlay that is version dependent may be required if not using `env.sh.eex`.


Source code is licensed under the [BSD 3-Clause License](LICENSE.md).

See the [Getting Started](#getting-started) section for more information on configuring your project for Horizon.


---
