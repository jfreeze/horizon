# Horizon Ops Helper Scripts

Horizon Ops Helper Scripts are a collection of scripts that help with the operational tasks of managing Horizon infrastructure. These scripts are designed to automate common tasks, such as setting up new hosts, configuring databases, and managing backups. By using these scripts, you can save time and reduce the risk of human error in your operations.

Below is a list of helper scripts available in the Horizon Ops Helper Scripts repository and a brief description of each script's purpose.

## freebsd_setup.sh

```
bsd_install.sh
Usage: freebsd_setup.sh [user@]host
```

The `freebsd_setup.sh` script automates the initial setup of a newly created FreeBSD host. This script automates configuration of elevated privileges, configures SSH keys, disables password login, and updates the system.

It performs the following tasks:
- Ensures `doas` command (replacement for `sudo`) is installed.
- Configures `doas.conf`
- Verifies SSH `authorized_keys` file is set up and disables password login.
- Runs `freebsd-update` to update the system.


## bsd_install.sh

This script automates the installation of packages on a remote FreeBSD host. 
It reads a configuration file and performs the install actions defined therein on the remote host.

```shell
bsd_install.sh
Usage: bsd_install.sh [--json] host config_file
  --json       Output in JSON format (optional)
  host         [user@]remote_host
  config_file  Path to the configuration file
```

See [Sample Host Configurations](sample-host-configurations.html) for examples of configuration files.

## add_certbot_crontab.sh

```
add_certbot_crontab.sh
Usage: ops/bin/add_certbot_crontab.sh [user@]host
```

Adds the cronjob for certbot to renew the SSL certificates and restart nginx.


## zfs_snapshot.sh

Backup script that runs locally on the postgres backup host.


## Transferring Databases

There are several scripts to help with transferring databases between hosts.

###	backup_databases.sh
```shell
backup_databases.sh

Usage: backup_databases.sh [-p port] [-U user] [-o output_dir] host

Options:
  -p port         PostgreSQL server port (default: 5432)
  -U user         PostgreSQL user (default: postgres)
  -o output_dir   Local directory to store backups (default: current directory)
```

Uses locally installed `psql` to backup all databases on a remote host and transfer them to the local host. Each database is compressed and saved as a separate file in the specified output directory.

###	`backup_databases_over_ssh.sh`
```shell
backup_databases_over_ssh.sh
Usage: backup_databases_over_ssh.sh [-o output_dir] [user@]host
```

If your database does not have an open port from which to backup, or if you don't have a compatible `psql` client, you can use this script to backup the databases over SSH. This script will connect to the remote host using `ssh` and run `psql` on the remote host to backup the databases.

### restore_database.sh

```shell
restore_database.sh

Usage: restore_database.sh [-p port] [-U user] [-d database] backup_file host

Options:
  -p port         PostgreSQL server port (default: 5432)
  -U user         PostgreSQL user (default: postgres)
  -d database     Database name to restore into

Arguments:
  backup_file     Path to the backup file (required)
  host            PostgreSQL server host (required)
```

This script restores a database from a backup file to a remote PostgreSQL server. It uses the `psql` client to connect to the remote server and restore the database from the specified backup file.

### update_database_owner.sh

```shell
update_database_owner.sh
Usage: update_database_owner.sh [-p port] [-U user] db_name target_user host
```

This script updates the owner of a database to a new user. It connects to the specified PostgreSQL server using `psql` at host `HOST` and changes the owner of the specified database to the target user.

## Control Postgres Access from External Hosts

If you have increased security concerns, Horizon provides scripts to toggle access to the PostgreSQL server from external hosts for individual users.

### turn_off_user_access.sh

```shell
Usage: turn_off_user_access.sh db_user [user@]remote_host
```
### turn_on_user_access.sh
```shell
Usage: turn_on_user_access.sh db_user [user@]remote_host
```

### turn_off_postgres_access.sh
```shell
turn_off_postgres_access.sh [user@]remote_host
```

### turn_on_postgres_access.sh
```shell
turn_on_postgres_access.sh [user@]remote_host
```
