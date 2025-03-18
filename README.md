# Horizon

Welcome to **Horizon**, an ops library for **deploying Elixir/Phoenix
projects** to FreeBSD hosts.

## Features
- Only SSH access is required for administration
- Uses install files so you can version manage host configuration
- Installs Elixir, Erlang, Postgres and creates Postgres databases
- Full Postgres install with a single command
- Tools to setup Postgres backup server
- Simplifies FreeBSD management on ZFS file systems
- Can deploy to bare-metal or VM hosts

## Getting Started

This guide is intended to help you get started with Horizon for deploying your Elixir/Phoenix application to FreeBSD hosts.
Follow the installation instructions on this page to configure your existing project to use Horizon for deployment.

Then follow the guides below to setup your host servers and deploy your Elixir/Phoenix application with Horizon.

- [Deploying with Horizon](deploying-with-horizon.html)
- [Horizon Ops Scripts](horizon-helper-scripts.html)
- [Sample Host Configurations](sample-host-configurations.html)
- [Proxy Configuration](proxy-conf.html)


### Additional Guides and Resources
- [FreeBSD Template Setup](freebsd-template-setup.html)
- [Hetzner Cloud Setup Guide](hetzner-cloud.html)
- [Hetzner Cloud Host Instantiation](hetzner-cloud-host-instantiation.html)
- [FreeBSD Installation](freebsd-install.html)
- [Creating a FreeBSD VM on Proxmox](proxmox.html)

## Installation

Add `horizon` to your list of dependencies in `mix.exs`:

```elixir
def deps do
 [
    {:horizon, "~> 0.2", runtime: false}
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

### Add a Release to your `mix.exs` file

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
          # release_commands: ["migrate"],
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

### Configure Runtime.exs for IPv4

If you are using a default `config/runtime.exs` file, it may ship with a default IPv6 listen address.
For the examples in this guide you will need to configure it for IPv4.

```elixir
  config :my_app1, MyApp1Web.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0},
      port: port
    ],
```

### Configure Host and Port in Runtime.exs

You may also need to configure the host and port in your `config/runtime.exs` file.
The host `demo-web` in this example is the name used in your browser to access your website.
This can be an actual domain name,  an IP address or an alias in your `/etc/hosts` file.

The `port` is the port number your Phoenix application will listen on. 
If you are running multiple applications in your Horizon setup, each application will need a unique port number.

```elixir
  host = System.get_env("PHX_HOST") || "demo-web1"
  port = String.to_integer(System.get_env("PORT") || "4000")
```


## Configuring Tailwind for FreeBSD

The default `setup` and `deploy` mix aliases for assets in a Phoenix project are:

```
"assets.setup": [
   "tailwind.install --if-missing",
   "esbuild.install --if-missing"
],
"assets.deploy": ["tailwind default", "esbuild default", "phx.digest"]
```

However, a tailwind download for FreeBSD is not currently provided by the Tailwind project.
This is resolved by passing a URL to `tailwind.install` from which to download the tailwind executable and creating FreeBSD-specific deployment commands.

**Two mix aliases are required for FreeBSD deployment:**

1. `assets.setup.freebsd`: For installing the FreeBSD-compatible Tailwind binary
2. `assets.deploy.freebsd`: For building and deploying assets on FreeBSD systems

These aliases will be different depending on the version of TailwindCSS you are using.

### For TailwindCSS v3

With TailwindCSS v3, you can use the following configuration:

```diff
+ @tailwindcss_freebsd_x64 "https://github.com/jfreeze/tailwind-freebsd-builder/releases/download/$version/tailwindcss-$target"
# or use files from dch
+ # @tailwindcss_freebsd_x64 "https://people.freebsd.org/~dch/pub/tailwind/v$version/tailwindcss-$target"
  ...
  defp aliases do
    [
      ...
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
+     "assets.setup.freebsd": [
+       "tailwind.install #{@tailwindcss_freebsd_x64}",
+       "esbuild.install --if-missing"
+     ],
+     "assets.deploy.freebsd": [ "assets.deploy" ]
      ...
    ]
  end
```
Note: Since the `--if-missing` flag does not work with `tailwind.install` when passing in a download URL, the `build_script.sh` will check if `tailwindcss` is installed before downloading. If it exists, it will not check for the existence of `esbuild`.

### For TailwindCSS v4

Using TailwindCSS v4 requires the `npm-node` package on the build host and a `assets/package.json` file in your project. Create this file with the following structure and your choice of versions:

```json
{
  "scripts": {
    "build:css": "./node_modules/.bin/tailwindcss -i ./css/app.css -o ../priv/static/assets/app.css --minify",
    "deploy:css": "NODE_ENV=production npm run build:css"
  },
  "dependencies": {
    "@tailwindcss/cli": "^4.0.8",
    "@tailwindcss/aspect-ratio": "^0.4.2",
    "@tailwindcss/forms": "^0.5.10",
    "@tailwindcss/typography": "^0.5.16",
    "detect-libc": "1.0.3",
    "enhanced-resolve": "^5.18.1"
  }
}
```

Then configure your mix aliases to use npm for asset compilation:

```diff
  ...
  defp aliases do
    [
      ...
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
+     "assets.setup.freebsd": [
+       "cmd --cd assets npm install",
+       "esbuild.install --if-missing"
+     ],
+     "assets.deploy.freebsd": [
+       "cmd --cd assets npm run deploy:css",
+       "esbuild my_app --minify",
+       "phx.digest"
+     ],
      ...
    ]
  end
```

Although not required, a more sophisticated alternative for `assets.setup.freebsd` is to check for `package-lock.json` and use `npm ci` for each build:

```diff
+     "assets.setup.freebsd": [
+       "cmd --cd assets \"sh -c 'if [ -f package-lock.json ]; then npm ci; else npm install; fi'\"",
+       "esbuild.install --if-missing"
+     ],
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
export PHX_SERVER=true
export SECRET_KEY_BASE=O7Delm59ZMLKlSh80ZnrBIhZmf6sz1NVMhbAofIxYNNZUqnkaa9SnizAA1jpxDl6
export PGHOSTADDR=10.0.0.3
export PHX_HOST=demo-web1

export DATABASE_URL=ecto://451f8d75-a808-11ef-8e9c-e1aff46a3315:0462ae2ea0e180b4beb0558bf5baec29e87c1ec9bd4f5c6c@$PGHOSTADDR/my_app1_prod
...
```

Update the `env.sh.eex` file with the environment variables required for your application.

> You can generate a secret key with:
> ```
> mix phx.gen.secret
> ```

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
