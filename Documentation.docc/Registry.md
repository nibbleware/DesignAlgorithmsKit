# Registry Pattern

Centralized registration and discovery of extensible types.

## Overview

The Registry Pattern provides a centralized way to register and discover types at runtime. This enables extensibility and plugin-like architectures.

## Usage

```swift
import DesignAlgorithmsKit

// Register a type
TypeRegistry.shared.register(MyType.self, key: "myType")

// Find registered type
if let type = TypeRegistry.shared.find(for: "myType") {
    // Use type
}
```

## Thread Safety

All operations are thread-safe using NSLock for synchronization.

## See Also

- ``TypeRegistry``
- ``Registrable``

