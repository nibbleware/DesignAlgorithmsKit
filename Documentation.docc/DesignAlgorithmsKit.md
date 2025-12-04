# DesignAlgorithmsKit

A Swift package providing common design patterns and algorithms with protocols and base types for extensibility.

## Overview

DesignAlgorithmsKit provides implementations of:
- **Design Patterns**: Classic patterns (Gang of Four) and modern patterns commonly used in Swift development
- **Algorithms**: Common algorithms and data structures (Merkle Tree, Bloom Filter, hashing, etc.)

All patterns and algorithms follow consistent implementation guidelines for maintainability, testability, and extensibility.

## Topics

### Design Patterns

#### Creational Patterns
- ``Singleton`` - Thread-safe singleton implementations
- ``Factory`` - Object creation without specifying concrete classes
- ``Builder`` - Step-by-step object construction with fluent API

#### Structural Patterns
- ``Facade`` - Simplified interface to complex subsystems
- ``Adapter`` - Adapting interfaces to client expectations

#### Behavioral Patterns
- ``Strategy`` - Interchangeable algorithms
- ``Observer`` - Event notification and subscription

#### Modern Patterns
- ``Registry`` - Centralized type registration and discovery

### Algorithms & Data Structures

#### Data Structures
- ``MerkleTree`` - Hash tree for efficient data verification
- ``BloomFilter`` - Probabilistic data structure for membership testing
- ``CountingBloomFilter`` - Bloom Filter variant that supports element removal

#### Hashing
- ``HashAlgorithm`` - Protocol for hash algorithms
- ``SHA256`` - SHA-256 hash algorithm implementation

## Getting Started

Add DesignAlgorithmsKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/rickhohler/DesignAlgorithmsKit.git", from: "1.0.0")
]
```

## See Also

- [GitHub Repository](https://github.com/rickhohler/DesignAlgorithmsKit)
- [Design Patterns Guide](https://en.wikipedia.org/wiki/Design_Patterns)
- [Merkle Tree](https://en.wikipedia.org/wiki/Merkle_tree)
- [Bloom Filter](https://en.wikipedia.org/wiki/Bloom_filter)

