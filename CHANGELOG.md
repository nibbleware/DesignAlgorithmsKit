# Changelog

All notable changes to DesignAlgorithmsKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- `StringExtractor.extractStrings` is linear in the data's size: it gathered each run a `Character` at a time and measured the string (`count`, linear) before every byte, so a run cost up to `maxLength` times its length. Runs are now gathered as bytes; the results are unchanged (checked against the previous implementation on random data).

## [1.12.0] - 2026-10-24

### Notes
- **ULID text format changed** (see Changed below): migrate stored ULID strings with `ULID(legacyString:)`.
- `TaskOrchestrator.execute()` now throws `OrchestrationError.taskFailure`; `ProcessingQueue.add`/`resume`/`retry` start items before returning.

### Added (`relocate-binary-readers-into-dak`)
- `DataReader`: sequential reader with offset tracking; throws `BinaryReadError.outOfBounds` and never advances on a short read.
- `BinaryDataReader`: big- and little-endian integer reads and writes at an offset. The named readers return 0, and the writers return `false`, when out of range; they never trap and do no misaligned loads. The generic `read(_:from:at:endian:)` and `write(_:to:at:endian:)` throw instead.
- `StringExtractor.extractStrings(from:minLength:maxLength:)`: printable runs, like `strings`.
- `BinaryReadError` and `ByteOrder`.
- All of them read `Data` slices relative to their start index. They replace FileSystemCore's copies of the same names.

### Changed (`platform-and-test-hygiene`)
- Building without CryptoKit is a compile-time error. The non-cryptographic placeholder that `SHA256.hash` returned on such platforms, and the `fatalError` paths in `MD5Strategy`/`SHA1Strategy`, are gone. `SHA256.hash(data:)` delegates to `SHA256Strategy`.
- Platform claims match the build: macOS 12 and iOS 15 (both built in CI). WASM, tvOS and watchOS are no longer claimed.
- The DocC catalog lives in the target (`Sources/DesignAlgorithmsKit/DesignAlgorithmsKit.docc`), and its symbol links resolve with no warnings.
- The gzip/gunzip interoperability tests moved to a separate `DesignAlgorithmsKitIntegrationTests` target (macOS, skipped when the tools are missing).
- Corrected doc comments for `FilenameTokenizer`, `ObjectFactory` and `HashAlgorithm`.

### Added (`platform-and-test-hygiene`)
- `HybridEncryption` tests.

### Removed (`platform-and-test-hygiene`)
- The empty `Algorithms/WASMGuard.swift` and its `exclude` entry.
- The GitHub Pages publish workflow and script. They needed `swift-docc-plugin`, which this package does not depend on, so they only ever published a static fallback page.
- The placeholder swift-testing `example()` test.

### Changed (`fix-ulid-spec-compliance`)
- **ULID text format:** `ULID.string`/`description` and `ULID(string:)` now follow the ULID specification (2 padding bits at the front, so the first character is `0`-`7`). `ULID(string:)` rejects strings starting above `7`. The 16 bytes are unchanged; only the text differs.
- **Migration:** strings stored by 1.10.x/1.11.x do not parse the same way. Read them with the new `ULID(legacyString:)` and re-save `string`. Known consumers: RetroboxBBS and RetroServe (TermFoundation).

### Added (`fix-async-work-correctness`)
- `ResourceCoordinator.withWriteLock(for:operation:)`.

### Fixed (`fix-async-work-correctness`)
- `JobManager.cancel(id:)` removes a pending job from the queue, so it never runs and stays `.failed`/"Cancelled".
- `TaskOrchestrator.execute()` throws `OrchestrationError.taskFailure(taskId:error:)` for a failing task; its dependents do not run. **Callers that caught the raw task error must unwrap `taskFailure`.**
- `ProcessingQueue` marks items `.processing` before spawning their task, so it never starts an item twice or exceeds `maxConcurrent`, and it drops finished task handles. `add`, `resume` and `retry` now start items before returning (pause the queue first to keep items pending).
- `ResourceCoordinator` releases a key's lock before `access` returns or throws and drops idle per-key lock state.

### Fixed (`fix-algorithm-edge-cases`)
- `MerkleTree.generateProof(for:)` adds a path entry for an unpaired node (its own hash as the right sibling), so proofs verify for every leaf of trees with an odd node count. Roots are unchanged.
- `BloomFilter` and `CountingBloomFilter` no longer trap on degenerate sizing: a capacity below 1 counts as 1 and the false-positive rate is clamped into (0, 1). `capacity` and `falsePositiveRate` report the clamped values.
- `Int.bloomHash()` uses the two's-complement bit pattern and no longer traps for negative values.
- `Gzip.decompress` verifies the CRC-32 and ISIZE trailer and throws `Gzip.Error.invalidData` on mismatch; XLEN is read little-endian; `Data` slices are accepted.

## [1.11.0] - 2026-10-24

### Added
- `Zlib` and `ZlibError`: in-memory zlib, gzip and raw DEFLATE compression/decompression with framing selected by window bits (`Zlib.Framing`), using `import zlib`
- `CRC32Checksum`: CRC-32 as `UInt32` with incremental `update(_:with:)`
- `FallbackTextDecoder`, `TextDecodingStrategy`, `StringEncodingStrategy`, `DecodedText`, `TextDecoderRegistry` and `Data.decodedText(using:)`: decode bytes of unknown encoding (US-ASCII, UTF-8, Mac OS Roman, Windows-1252) with pluggable strategies and control-character stripping

### Changed
- `Gzip` is built on `Zlib`; the `@_silgen_name` zlib proxy and hand-written `z_stream` layout are removed
- `CRC32Strategy` uses `CRC32Checksum`
- `DesignAlgorithmsKit.version` is `1.11.0`
- README rewritten to match the code: purpose, products, platforms, dependencies, build/test, known issues

### Fixed
- `Gzip.compress` no longer overflows an integer literal on 32-bit targets

### Removed
- `docs/DESIGN_PATTERNS.md` and `docs/EXAMPLES.md` (examples used APIs that do not exist; superseded by the README)
- Committed `.swiftpm/xcode/xcuserdata` (now git-ignored)

### Notes
- Releases v1.8.0 (FilenameTokenizer, UUIDv5Generator), v1.9.0 (Visitor, Graph, Gzip) and v1.10.0 were tagged without CHANGELOG entries; backfill is tracked in `platform-and-test-hygiene`

## [1.10.0] - 2026-02-04

### Changed
- `.gitignore` excludes `.build` and other build artifacts.

### Notes
- A MerkleTree consolidation was merged and reverted before the tag; the public API matches 1.9.0.

## [1.9.0] - 2026-01-02

### Added
- `Visitor` pattern and `Graph` data structure (#14).
- `Gzip` in-memory GZIP compression and decompression (#15).

## [1.8.0] - 2025-12-29

### Added
- `UUIDv5Generator` for name-based (RFC 4122 version 5) UUIDs.
- `FilenameTokenizer` for splitting file names into words (#13).

## [1.7.0] - 2025-12-21

### Added
- `UUIDv5Generator` for deterministic UUID generation from namespace and name

### Fixed
- Fixed compiler warnings in `JobManager.swift` (removed unnecessary `await`)

### Changed
- Improved test coverage for `Singleton`, `Merger`, `TaskOrchestrator`, and `HashAlgorithmProtocol`

## [v1.4.1] - 2025-12-13

### Added
- `ThreadSafeArray` and `ThreadSafeDictionary`

### Changed
- Boosted unit test coverage across multiple patterns (Builder, Factory, Adapter, Facade, Observer, Strategy)

## [v1.4.0] - 2025-12-12

### Added
- `Data` extensions for convenient SHA256 hashing (`sha256`, `sha256Hex`)

### Changed
- Improved error handling in `HashComputation` to use `LocalizedError` with descriptive messages

### Fixed
- Fixed compiler warnings in `MergerTests` regarding `Sendable` conformance and unnecessary `await`
- Fixed type mismatch errors in `HashComputationTests`

## [v1.3.0] - 2025-12-12

### Changed
- Bumped version to 1.3.0

## [v1.2.2] - 2025-12-12

### Added
- `Codable` conformance to `HashAlgorithm`

## [v1.2.1] - 2025-12-12

### Fixed
- Restructured `HashComputation` to root level for proper exports

## [v1.2.0] - 2025-12-12

### Added
- HashComputation feature

## [1.1.0] - 2025-12-04

### Added
- **Queue Processing Pattern** - Concurrent queue management with status tracking, progress monitoring, and retry support
  - `QueueItem` protocol for items that can be processed in a queue
  - `QueueProcessor` protocol for processing queue items
  - `ProcessingQueue` actor for managing concurrent processing with configurable limits
  - Features: status tracking (pending, processing, completed, failed), progress monitoring (0.0 to 1.0), retry support, pause/resume functionality, cancellation, deduplication
  - Comprehensive unit tests (15 tests)
- **Merging/Upsert Pattern** - Configurable merge strategies for conflict resolution
  - `Mergeable` protocol for types that can be merged
  - `MergeStrategy` enum with strategies: preferExisting, preferNew, combine, custom
  - `Merger` protocol for merging items with configurable strategies
  - `DefaultMerger` base class with default implementations
  - Comprehensive unit tests (32 tests)
- Added comprehensive unit tests for new patterns
  - Queue Processing Pattern: 15 tests covering all features and edge cases
  - Merging/Upsert Pattern: 32 tests covering all strategies, edge cases, and protocol conformance
  - Total: 153 tests (was 123) ➕ +30 new tests

### Changed
- Updated README.md with usage examples for Queue Processing Pattern and Merging/Upsert Pattern
- Improved code coverage:
  - Overall: 96.15% lines (up from 96.06%)
  - Queue.swift: 89.23% regions, 91.50% lines
  - Merger.swift: 83.33% regions, 84.62% lines
- Enhanced documentation with comprehensive examples for new patterns

### Fixed
- N/A

## [1.0.3] - 2025-12-04

### Added
- Added comprehensive unit tests for Builder pattern (12 tests total)
  - Test for BaseBuilder default implementation (notImplemented error)
  - Tests for BuilderError localizedDescription for all error cases
  - Test for fluent API chaining with multiple method calls
  - Test for optional properties handling
  - Test for multiple independent builder instances
  - Test for ValidatingBuilderProtocol default implementation
  - Comprehensive validation tests with multiple rules
  - Test for error pattern matching
  - Test for builder reuse scenarios
- Added comprehensive unit tests to improve code coverage
  - Added tests for Singleton createShared() path and init()
  - Added tests for BaseStrategy and StrategyContext edge cases
  - Added tests for Factory error handling, thread safety, and edge cases
  - Added tests for Registry protocol method, default keys, and thread safety
- Added tests for HashAlgorithm extension fallback behavior
- Added test for HashAlgorithm string extension consistency
- Added SingletonError enum for better error handling in Singleton pattern

### Changed
- Refactored Singleton.createShared() to throw SingletonError instead of fatalError
  - Makes the error path testable while maintaining fatalError for production use
  - Improved Singleton function coverage from 50% to 80%
- Refactored HashAlgorithm extension to improve testability
  - Added documentation explaining UTF-8 conversion fallback behavior
  - Documented fallback hash path as conditionally untestable
- Improved overall code coverage:
  - Regions: 87.31% → 87.75%
  - Functions: 88.24% → 90.29%
  - Lines: 90.91% → 91.38%

### Fixed
- Fixed compiler warning in SingletonTests about 'is' test always being true
- Fixed Builder pattern testability - improved coverage to 100% (from 66.67%)
- Fixed test for StrategyContext with same strategy type

### Documentation
- Added documentation explaining why fatalError path in Singleton.shared cannot be tested
- Added documentation to HashAlgorithm fallback implementation explaining conditional testability
- Improved code documentation for testability throughout codebase

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

