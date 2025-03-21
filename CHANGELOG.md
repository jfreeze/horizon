# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.3] - 2025-03-18
### Changed
- Removed confusing VERSION from deploy script output.


## [0.3.2] - 2025-03-18
### Fixed
- Fixed missing host in final instructions at the end of freebsd_setup.sh

### Added
- Added example `release_commands: ["migrate"]` to README.md as a better default than `[""]`.
- Added mix task `horizon.git.gen.git_ref` convenience task to write the git ref to a file that can be used as part of the version. It is the users responsibility to add the file to .gitignore.
- Added `env_path` so that builds that use `compile_env` may load the environment from a file so compiling can succeed.
- Added `mix deps.clean <@app> --build` to the build stage to automatically recover from changed environment variables.


## [0.3.0] - 2025-02-27

### Changed
- Combined user and host changing Horizon.NginxConf.send/4 to Horizon.NginxConf.send/3
- Now require the mix alias `assets.setup.freebsd` to accommodate TailwindCSS v3 and v4.
- Now require the mix alias `assets.deploy.freebsd` for asset deployment on FreeBSD with TailwindCSS v3 and v4 support.

### Added
- Added ability to build assets with [TailwindCSS v4](README.md#for-tailwindcss-v4).
- Added `npm-node23` to `build.conf` samples for TailwindCSS v4.
- Added `--reset` option to `stage` script to clear build artifacts.
- Added `assets/node_modules` and `assets/package-lock.json` to the stage exclusion list.
- Added version stamp to all scripts for improved source tracking.

### Fixed
- Fixed typo in documentation changing `letsencrypt_live` to `letsencrypt_domain`.
- Fixed docs compilation issue.
- Fixed incorrect env var override in stage script documentation. Corrected `BUILD_USER_SSH` to `BUILD_HOST_SSH`


## [0.2.7] - 2025-02-01

### Fixed
- Fixed issue in `Horizon.NginxConf.generate` where the static file config was not redirecting to https.


## [0.2.6] - 2025-01-29

### Added
- `Horizon.Project.static_index` is available to set a static index file. Useful for maintenance periods.
- Option `Horizon.Project.static_index_root` is available to set the root directory for the static index file.
- `Horizon.NginxConfig.generate/2` now accepts a list of options. See `Horizon.NginxConfig`
- `Horizon.NginxConfig.send/3` now accepts a list of options. See `Horizon.NginxConfig`

### Fixed
- Fixed issue in bsd_install.sh where the last line of the config was not being processed if it did not end with a newline.
- Fixed bug in `Horizon.NginxConfig` where an empty server list does not add an `upstream` block to the config file.
- Fixed issue with `bsd_install.sh` that installed head of elixir instead of the requested version.

### Changed
- Updated `README.md` documentation.
- Updated `proxy-conf.livemd` sample.


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
- Moved last two arguments of NginxConfig.send/3 to opts
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
[0.3.2]: https://github.com/jfreeze/horizon/tree/0.3.2
[0.3.0]: https://github.com/jfreeze/horizon/tree/0.3.0
[0.2.7]: https://github.com/jfreeze/horizon/tree/0.2.7
[0.2.6]: https://github.com/jfreeze/horizon/tree/0.2.6
[0.2.5]: https://github.com/jfreeze/horizon/tree/0.2.5
[0.2.4]: https://github.com/jfreeze/horizon/tree/0.2.4
[0.2.3]: https://github.com/jfreeze/horizon/tree/0.2.3
[0.1.3]: https://github.com/jfreeze/horizon/tree/0.1.3
[0.1.2]: https://github.com/jfreeze/horizon/tree/0.1.2
[0.1.1]: https://github.com/jfreeze/horizon/tree/0.1.1
