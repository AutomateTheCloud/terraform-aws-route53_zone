# Changelog

All notable changes to this module are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module uses [semantic versioning](https://semver.org/): a new major version means callers must change their code.

## [Unreleased]

## [1.0.1] - 2026-10-06

### Changed

- The copyright year in `NOTICE` and the file headers is now 2026, the year the module was rebuilt and released as 1.0.0.
- `CLAUDE.md`, the working rules shared by every Automate the Cloud module, adds the lessons learned while rebuilding the modules.

## [1.0.0] - 2026-10-05

Initial release.

### Added

- A public Route 53 hosted zone, or a private one for a list of VPCs, which can be in different Regions.
- VPC associations managed in place: adding or removing a VPC does not replace the zone.
- A default comment that names the zone and says whether it is public or private.
- A reusable delegation set, so several public zones can share the same name servers.
- Protection against a destroy deleting records, unless `force_destroy` is turned on.
- `region`, for the Region of the VPCs and of the `metadata` output, without configuring another provider.
- A `metadata` output with everything the module created, including the zone's ID and name servers.
- Offline tests, and examples for a public zone, a private zone for VPCs in two Regions, and zones that share name servers.

[Unreleased]: https://github.com/AutomateTheCloud/terraform-aws-route53_zone/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/AutomateTheCloud/terraform-aws-route53_zone/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/AutomateTheCloud/terraform-aws-route53_zone/releases/tag/v1.0.0
