# Merkle Tree

A hash tree data structure used for efficient verification of large data structures.

## Overview

A Merkle tree is a tree in which every leaf node is labeled with the hash of a data block, and every non-leaf node is labeled with the hash of the labels of its child nodes.

## Usage

```swift
import DesignAlgorithmsKit

// Build Merkle tree from data
let data = ["block1", "block2", "block3", "block4"].map { $0.data(using: .utf8)! }
let tree = MerkleTree.build(from: data)

// Get root hash
let rootHash = tree.rootHash

// Generate proof for a specific leaf
if let proof = tree.generateProof(for: data[0]) {
    // Verify proof
    let isValid = MerkleTree.verify(proof: proof, rootHash: rootHash)
}
```

## See Also

- ``MerkleTree``
- ``MerkleProof``
- ``MerkleHashable``

