# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Added functionality for connecting to VM providers to create host instances (starting with GCE VM hosts).
- Introduced `Horizon.Target` module utilizing ADTs for deployment targets.
- Added features to install and configure PostgreSQL on FreeBSD hosts.
- Implemented initial support for setting up a database follower and moving the master.

### Changed
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

[Unreleased]: https://github.com/yourusername/Horizon/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/yourusername/Horizon/releases/tag/v0.1.0