# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]


## [0.1.3] - 2024-10-29
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
