# Changelog

All notable changes to DesignAlgorithmsKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- N/A

### Changed
- N/A

### Deprecated
- N/A

### Removed
- N/A

### Fixed
- N/A

### Security
- N/A

## [1.0.2] - 2025-12-04

### Fixed
- Fixed duplicate `import Foundation` statement in `MerkleTree.swift`
- Fixed compiler warnings in `BuilderTests.swift` about unused mutable variables
  - Changed `var newBuilder = self` pattern to direct `self` mutation
  - Since `BaseBuilder` is a class (reference type), we can mutate `self` directly

## [1.0.1] - 2025-12-04

### Changed
- Fixed workflow YAML syntax errors that prevented execution
- Renamed workflow file to `publish-github-pages.yml` for consistency with project standards
- Refactored workflow to use shell script approach matching the 'me' project pattern
- Added `publish-docc-to-github-pages.sh` script for documentation generation and publishing
- Updated permissions to use `contents:write` instead of `pages:write`
- Added Git configuration step for GitHub Actions
- Added support for `GH_PAT` token fallback for cross-repository access

## [1.0.0] - 2025-12-04

### Added
- Initial release with core design patterns and algorithms
- Registry Pattern implementation
- Factory Pattern implementation
- Builder Pattern implementation
- Singleton Pattern implementation
- Strategy Pattern implementation
- Observer Pattern implementation
- Facade Pattern implementation
- Adapter Pattern implementation
- Merkle Tree data structure
- Bloom Filter data structure
- Counting Bloom Filter variant
- SHA-256 hash algorithm
- Comprehensive unit test suite (67 tests)
- DocC documentation
- GitHub Actions CI/CD workflows
- Code coverage reporting

