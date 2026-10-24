# DesignAlgorithmsKit

[![Tests](https://github.com/nibbleware/DesignAlgorithmsKit/workflows/Tests/badge.svg)](https://github.com/nibbleware/DesignAlgorithmsKit/actions)

DesignAlgorithmsKit (DAK) is a general-purpose, domain-agnostic Swift library of reusable design patterns, concurrency helpers and algorithms. It has no dependencies of its own and must not contain file-system, platform, inventory or app concepts; generic code found in packages built on it belongs here.

## Products

One library product and target: **`DesignAlgorithmsKit`** (`Sources/DesignAlgorithmsKit`).

| Area | Types |
| --- | --- |
| Registries | `TypeRegistry`, `Registrable`, `Registry<Key, Value>` |
| Singletons | `ThreadSafeSingleton`, `Singleton`, `ActorSingleton`, `SingletonError` |
| Factory / builder | `ObjectFactory`, `FactoryProduct`, `FactoryError`, `BaseBuilder`, `BuilderError`, `ValidatingBuilderProtocol` |
| Thread-safe containers | `ThreadSafe<Value>`, `ThreadSafeArray`, `ThreadSafeDictionary` |
| Structural patterns | `BaseAdapter`, `BaseFacade`, `BaseDecorator`, `Composite`/`Leaf`/`BaseComponent` |
| Behavioral patterns | `StrategyContext`, `BaseStrategy`, `BaseObservable`/`Observer`, `CommandInvoker`/`ClosureCommand`, `BaseHandler`/`BaseTypedHandler`, `ArrayIterator`/`TreeIterator`, `Visitor`/`Visitable`, `Mergeable`/`MergeStrategy`/`DefaultMerger` |
| Pipelines | `DataPipeline`, `AsyncDataPipeline`, `AnyAsyncPipelineStage`, `DynamicAsyncPipeline`, `PipelineError` |
| Async work | `ProcessingQueue`/`QueueItem`/`QueueProcessor`, `JobManager`, `TaskOrchestrator`/`DAGTask`, `ResourceCoordinator` |
| Hashing | `HashAlgorithm` (SHA-256, SHA-1, MD5, CRC-32), `HashComputation`, `HashStrategy`/`HashStrategyRegistry`, `SHA256`, `Data.sha256`/`sha256Hex`, `CRC32Checksum` (`UInt32`, incremental) |
| Identifiers | `ULID`, `UUIDv5Generator` |
| Probabilistic filters | `BloomFilter`, `CountingBloomFilter`, `BloomFilterHashable` |
| Merkle tree | `MerkleTree`, `MerkleProof`, `MerkleHashable` |
| Graphs | `Graph<T>` (directed, BFS reachability, unreachable-node detection) |
| Compression | `Zlib`/`ZlibError` (zlib, gzip and raw DEFLATE framing by window bits, via system zlib), `Gzip` (in-memory GZIP) |
| Encryption | `HybridEncryption` (Curve25519 + HKDF-SHA256 + ChaCha20-Poly1305) |
| Text / paths | `FilenameTokenizer`, `GitObjectLayout`, `FallbackTextDecoder`/`TextDecodingStrategy`/`StringEncodingStrategy`/`TextDecoderRegistry`, `Data.decodedText(using:)` |

## Platforms

`Package.swift` declares macOS 12 and iOS 15, with swift-tools-version 5.10. The library imports CryptoKit and links the system zlib, so in practice it builds only for Apple platforms. The older WASM, tvOS and watchOS claims are not backed by the build.

## Dependencies

- **Direct package dependencies:** none. The package links the system library `z` and uses Foundation and CryptoKit.
- **Tree** (`swift package show-dependencies`):
  ```
  DesignAlgorithmsKit
  └── (no external dependencies)
  ```
- **How consumers reference DAK.** The canonical remote is `https://github.com/nibbleware/DesignAlgorithmsKit.git`, and `rickhohler/DesignAlgorithmsKit` redirects to it. Use a semver range:
  ```swift
  .package(url: "https://github.com/nibbleware/DesignAlgorithmsKit.git", from: "1.11.0")
  ```
  The latest tag is `v1.11.0`.

## Usage

```swift
import DesignAlgorithmsKit

// Keyed registry (thread-safe)
final class CodecRegistry: Registry<String, any Codec> {}
let codecs = CodecRegistry()
codecs.register(MyCodec(), for: "my")

// Lazily created, per-type singleton
final class Settings: ThreadSafeSingleton {
    override class func createShared() throws -> Settings { Settings() }
}
let settings = Settings.shared

// Hashing
let hex = try HashComputation.computeHashHex(data: data, algorithm: .sha256)
let crc = HashComputation.computeCRC32(data: data)        // 4 bytes, big-endian

// Identifiers
let id = UUIDv5Generator.generate(namespace: ns, name: "python.org")

// GZIP
let gz = try Gzip.compress(data: data)
let raw = try Gzip.decompress(data: gz)

// zlib with explicit framing (15 zlib, 31 gzip, -15 raw DEFLATE)
let deflated = try Zlib.compress(data: data, windowBits: -15)
let inflated = try Zlib.decompress(data: deflated, framing: .rawDeflate)
let crc32 = CRC32Checksum.checksum(data)                    // UInt32

// Text of unknown encoding: US-ASCII, UTF-8, Mac OS Roman, Windows-1252,
// control characters (except newlines and tabs) removed
let text = bytes.decodedText()
// Add your own character sets before or after the defaults
TextDecoderRegistry.shared.register(MyCharsetStrategy(), placement: .beforeDefaults)
let custom = TextDecoderRegistry.shared.decode(bytes)
```

## Build & test

```sh
swift build
swift test
```

- No other packages are needed to build DAK.
- Current baseline: `swift build` succeeds with two warnings, and `swift test` runs 343 XCTest tests and 1 swift-testing placeholder with 0 failures.
- `IntegrationCompressionTests` runs `/usr/bin/gzip` and `/usr/bin/gunzip`, so it needs macOS.

## Known issues

- `JobManager.cancel` does not stop a pending job; `TaskOrchestrator` never throws `taskFailure`; `ProcessingQueue` has a scheduling race; `ResourceCoordinator` releases locks late.
- Merkle proofs fail for unpaired leaves; Bloom filters trap on capacity 0, rate 0 or a negative `Int`; `Gzip.decompress` ignores the CRC and ISIZE trailer.
- `ULID` text is not compatible with the ULID specification.
- Platform claims are broader than tested, `WASMGuard.swift` is dead code, SHA code is duplicated, and the DocC catalog is not attached to the target.

## Documentation

- `Documentation.docc/`: DocC articles. They are not yet attached to the target.
- [CHANGELOG.md](CHANGELOG.md), [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md), [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License

MIT. See [LICENSE](LICENSE).
