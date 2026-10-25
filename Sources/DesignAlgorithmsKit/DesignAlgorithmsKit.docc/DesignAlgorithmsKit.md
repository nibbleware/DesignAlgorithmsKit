# ``DesignAlgorithmsKit``

A Swift package providing common design patterns and algorithms with protocols and base types for extensibility.

## Overview

DesignAlgorithmsKit provides implementations of:
- **Design Patterns**: Classic patterns (Gang of Four) and modern patterns commonly used in Swift development
- **Algorithms**: Common algorithms and data structures (Merkle Tree, Bloom Filter, hashing, etc.)

All patterns and algorithms follow consistent implementation guidelines for maintainability, testability, and extensibility.

## Topics

### Articles

- <doc:RegistryPattern>
- <doc:UsingMerkleTrees>
- <doc:UsingBloomFilters>

### Design Patterns

#### Creational Patterns
- ``ThreadSafeSingleton``
- ``ObjectFactory``
- ``BaseBuilder``

#### Structural Patterns
- ``BaseFacade``
- ``BaseAdapter``

#### Behavioral Patterns
- ``StrategyContext``
- ``BaseObservable``

#### Modern Patterns
- ``TypeRegistry``
- ``Registry``

### Algorithms & Data Structures

#### Data Structures
- ``MerkleTree``
- ``BloomFilter``
- ``CountingBloomFilter``

#### Hashing
- ``HashAlgorithm``
- ``HashComputation``
- ``SHA256``

## Getting Started

Add DesignAlgorithmsKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/nibbleware/DesignAlgorithmsKit.git", from: "1.11.0")
]
```

## See Also

- [GitHub Repository](https://github.com/nibbleware/DesignAlgorithmsKit)
- [Design Patterns Guide](https://en.wikipedia.org/wiki/Design_Patterns)
- [Merkle Tree](https://en.wikipedia.org/wiki/Merkle_tree)
- [Bloom Filter](https://en.wikipedia.org/wiki/Bloom_filter)

