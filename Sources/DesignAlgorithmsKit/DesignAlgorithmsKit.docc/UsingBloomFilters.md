# Bloom Filter

A probabilistic data structure for membership testing.

## Overview

A Bloom filter is a space-efficient probabilistic data structure that is used to test whether an element is a member of a set. False positive matches are possible, but false negatives are not.

## Characteristics

- **Space Efficient**: Uses much less memory than storing all elements
- **Fast**: O(k) time complexity where k is the number of hash functions
- **Probabilistic**: May return false positives, but never false negatives
- **Immutable**: Once built, cannot remove elements (use Counting Bloom Filter for that)

## Usage

```swift
import DesignAlgorithmsKit

// Create Bloom Filter with expected capacity and false positive rate
let filter = BloomFilter(capacity: 1000, falsePositiveRate: 0.01)

// Add elements
filter.insert("element1")
filter.insert("element2")
filter.insert("element3")

// Check membership
if filter.contains("element1") {
    // Element might be in set (could be false positive)
}

if !filter.contains("element4") {
    // Element is definitely NOT in set
}
```

## Counting Bloom Filter

For removable elements, use ``CountingBloomFilter``:

```swift
let countingFilter = CountingBloomFilter(capacity: 1000, falsePositiveRate: 0.01)
countingFilter.insert("item1")
countingFilter.remove("item1")
```

## See Also

- ``BloomFilter``
- ``CountingBloomFilter``
- ``BloomFilterHashable``

