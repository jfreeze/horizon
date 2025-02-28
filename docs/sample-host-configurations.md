# Sample Host Configurations

This guide contains sample configuration files for setting up a multi-host environment with Horizon.
Using these sample files you can build the host collateral that you need to deploy your Elixir/Phoenix application.

## Build Host

We start with a sample config file for a build host. 
The only expectation for this host is to build a release but not run the application.

This config file uses the current pkg version of erlang `erlang-runtime27` and builds Elixir 1.18.2 from source.

The `path` is set to the erlang bin directory and must precede the Elixir install.
This dynamically sets the path so the Elixir installer knows where to find Erlang.

> **Note:** The `path` is dependent upon the version of erlang that is installed and you will need to update it accordingly.

```build.conf
pkg:ca_root_nss
pkg:gcc
pkg:rsync
pkg:gmake
pkg:git
pkg:erlang-runtime27

# For Tailwind v4
pkg:npm-node23

# Store the path to erlang for builds via bsd_install.sh
dot-path:/usr/local/lib/erlang27/bin

# Set the path to erlang (on the fly) so we can install elixir
path:/usr/local/lib/erlang27/bin

elixir:1.18.2
```

You can now configure the `demo-build` build host with:

```shell
./ops/bin/bsd_install.sh admin@demo-build build.conf
```

## Web Host

A `web` host only needs application specific packages. For example, if your app needs `vips` for use with `vix`, you can install it here.

In this example, the web host does not need any additional packages.

## Proxy Host

The `reverse-proxy` host is used to route traffic to the web host. It needs to have Nginx installed and configured to route traffic to the web hosts.

We also install `certbot` on this host to manage SSL certificates.

The `proxy.conf` file for the `reverse-proxy` host looks like:

```proxy.conf
pkg:nginx
service:nginx
pkg:py311-certbot
```

The `pkg` commands install the packages and the `service` command starts the Nginx service.

In this example, we are going to configure the `demo-web1` host as the proxy host:

```
./ops/bin/bsd_install.sh admin@demo-web1 proxy.conf
```

## Postgres Host

The postgres host is your primary database server.

There are four steps to getting Postgres up and running:

1. Install the version of postgres server and contrib library of your choice
2. Configure zfs for database snapshots.
3. Initialize postgres. This configures `postgresql.conf`, `pg_hba.conf` and logging. Logging is at `/var/log/postgresql.log`
4. Create a database. Creating a database creates a user/password, and updates `pg_hba.conf`. You can also choose the locale and `ctype` of the database.

### Creating a Database

When creating a database you need to specify how it is to sort strings and how text is encoded. Horizon provides three options:

- `postgres-db-c_mixed_utf8`
- `postgres-db-c_utf8_full`
- `postgres-db-us_utf8_full`

The `c` in `c_mixed_utf8` and `c_utf8_full` stands for `C` locale. This locale sorts strings by byte order. The `us` in `us_utf8_full` stands for `US` locale. This locale sorts strings by dictionary order.

> **If you plan on running physical backups with zfs, install `postgres.zfs-init` BEFORE `postgres.init`.** If `/var/db/postgres/data<version>` already exists, you will need to create a new zfs dataset manually and move the data directory to the new dataset.

The `postgres.conf` file for the `postgres` host looks like:

```postgres.con
pkg:postgresql17-server
pkg:postgresql17-contrib
postgres.zfs-init
postgres.init

# Encode with UTF8 and sort with byte order
postgres.db:c_mixed_utf8:mydb

# Other postgresql options
#postgres.db:us_utf8_full:mydb
#postgres.db:c_utf8_full:mydb
```

Configure your postgres host with:

```
./ops/bin/bsd_install.sh admin@demo-pg1 postgres.conf
```

## Postgres Backup Host

The postgres backup host is used to store backups of the postgres database.
For this host you don't need to initialize postgres, but you do need to install the postgres server, the contrib library and initialize `zfs`.

The `postgres-backup.conf` file for the `postgres-backup` host looks like:

```postgres-backup.conf
pkg:postgresql17-server
pkg:postgresql17-contrib
postgres.zfs-init
```

Setup the postgres backup host with:

```
./ops/bin/bsd_install.sh admin@demo-pg2 postgres-backup.conf
```

That's it! You now have hosts ready for start your Elixir/Phoenix application deployment with Horizon.

---
