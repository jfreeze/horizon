# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]



## [0.3.0]

### Added
- Horizon.Project.static_index is available to to set a static index file. Useful for maintenance periods.
- Option Horizon.Project.static_index_root is available to set the root directory for the static index file.
- Horizon.NginxConfig.generate/2 now accepts a list of options. See `Horizon.NginxConfig`
- Horizon.NginxConfig.send/4 now accepts a list of options. See `Horizon.NginxConfig`


### Changed
- Updated README.md documentation.

## [0.2.5] - 2024-12-05
### Added
- Added `-n` option to `restore_database.sh` to activate the `--no-owner` option on `pg_restore`.



## [0.2.4] - 2024-12-02
### Changed
- Cleaned up Deploying with Horizon docs.



## [0.2.3] - 2024-11-29
### Added
- Added proxmox VM creation guide.
- Added CHANGELOG.md to Hex page.



## [0.2.2]
### Changed
- Compressed images in docs.



## [0.2.1]
### Fixed
- Fixed document links in README.md.



## [0.2.0]
### Added
- Added ssl headers to nginx.conf (NginxConfig.generate/4)
- Added `mix horizon.ops.init` to install HorizonOps scripts.
- Added .ssh/environment file to store environment variables for ssh connections.
- Added --verbose option on bsd_install.sh (similar to debug)
- Added docs for Horizon Ops scripts.
- Added docs for Proxmox setup.
- Added docs for FreeBSD Install
- Added docs for Hetzner Cloud setup
- Added sample config files for hosts, e.g. [build, web, pg, backup]

### Changed
- Moved last two arguments of NginxConfig.send/4 to opts
- Changed log_duration to `off` in postgresql.conf to save space.
- Changed log_statement to `ddl` in postgresql.conf to save space.
- Changed `mix horizon.init` to only install project specific deploy scripts.
- Removed `-u user` option on ops scripts and included optional [user@] for hosts

### Fixed
- Fixed bug in NginxConfig.generate to properly handle multiple server names.



## [0.1.3]
### Changed
- Added `freebsd_setup.sh` script to help setup first-boot configuration for FreeBSD hosts.
- Changed host on `bsd_install.sh` to combine user and host into a single argument.
- Added `postgres.zfs-init` command to `bsd_install.sh` script.

### Fixed
- Fixed documentation issues.



## [0.1.2] - 2024-10-29
### Changed
- Updates for adding to Hex

## [0.1.1] - 2024-10-29
### Added
- Added zfs_snapshot script
- Added functionality for connecting to VM providers to create host instances (starting with GCE VM hosts).
- Introduced `Horizon.Target` module utilizing ADTs for deployment targets.
- Added features to install and configure PostgreSQL on FreeBSD hosts.
- Implemented initial support for setting up a database follower and moving the master.

### Changed
- Updated postgres.conf comments
- Renamed the project from "Horizon" to "HorizonOps".
- Updated the structure to include components like `Horizon.GCE`, `Horizon.AWS`, `HorizonBSD`, and `HorizonLinux`.

### Fixed
- Minor bug fixes related to FreeBSD deployment scripts.

## [0.1.0] - 2024-10-19
### Added
- Initial release of Horizon.
- Scripts for deploying Phoenix applications to FreeBSD hosts.
- Tools for configuring FreeBSD hosts with Elixir/Phoenix releases.
- Basic support for PostgreSQL installation and configuration on FreeBSD.

[Unreleased]: https://github.com/jfreeze/horizon/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/jfreeze/horizon/tree/0.1.1
[0.1.2]: https://github.com/jfreeze/horizon/tree/0.1.2
[0.1.3]: https://github.com/jfreeze/horizon/tree/0.1.3
[0.2.3]: https://github.com/jfreeze/horizon/tree/0.2.3
[0.2.4]: https://github.com/jfreeze/horizon/tree/0.2.4
[0.2.5]: https://github.com/jfreeze/horizon/tree/0.2.5
