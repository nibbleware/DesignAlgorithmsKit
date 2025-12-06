//
//  BloomFilter.swift
//  DesignAlgorithmsKit
//
//  Bloom Filter - A probabilistic data structure for membership testing
//

#if !os(WASI)
import Foundation

/// Protocol for types that can be hashed for Bloom Filter
public protocol BloomFilterHashable {
    /// Generate hash for this value
    /// - Returns: Hash value as UInt64
    func bloomHash() -> UInt64
}

extension String: BloomFilterHashable {
    public func bloomHash() -> UInt64 {
        // Use a proper hash function for strings
        var hash: UInt64 = 5381
        for char in self.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(char)
        }
        return hash
    }
}

extension Data: BloomFilterHashable {
    public func bloomHash() -> UInt64 {
        var hash: UInt64 = 5381
        self.withUnsafeBytes { bytes in
            for byte in bytes {
                hash = ((hash << 5) &+ hash) &+ UInt64(byte)
            }
        }
        return hash
    }
}

extension Int: BloomFilterHashable {
    public func bloomHash() -> UInt64 {
        return UInt64(self)
    }
}

extension UInt64: BloomFilterHashable {
    public func bloomHash() -> UInt64 {
        return self
    }
}

/// Bloom Filter - A probabilistic data structure for membership testing
///
/// A Bloom filter is a space-efficient probabilistic data structure that is used
/// to test whether an element is a member of a set. False positive matches are
/// possible, but false negatives are not.
///
/// ## Characteristics
///
/// - **Space Efficient**: Uses much less memory than storing all elements
/// - **Fast**: O(k) time complexity where k is the number of hash functions
/// - **Probabilistic**: May return false positives, but never false negatives
/// - **Immutable**: Once built, cannot remove elements (use Counting Bloom Filter for that)
///
/// ## Usage
///
/// ```swift
/// import DesignAlgorithmsKit
///
/// // Create Bloom Filter with expected capacity and false positive rate
/// let filter = BloomFilter(capacity: 1000, falsePositiveRate: 0.01)
///
/// // Add elements
/// filter.insert("element1")
/// filter.insert("element2")
/// filter.insert("element3")
///
/// // Check membership
/// if filter.contains("element1") {
///     // Element might be in set (could be false positive)
/// }
///
/// if !filter.contains("element4") {
///     // Element is definitely NOT in set
/// }
/// ```
public final class BloomFilter {
    /// Bit array for storing filter bits
    private var bits: [Bool]
    
    /// Number of bits in the filter
    public let bitCount: Int
    
    /// Number of hash functions to use
    public let hashFunctionCount: Int
    
    /// Expected capacity (number of elements)
    public let capacity: Int
    
    /// Target false positive rate
    public let falsePositiveRate: Double
    
    /// Number of elements inserted
    private(set) public var elementCount: Int = 0
    
    /// Lock for thread-safe access
    private let lock = NSLock()
    
    /// Initialize Bloom Filter
    /// - Parameters:
    ///   - capacity: Expected number of elements to be inserted
    ///   - falsePositiveRate: Desired false positive rate (0.0 to 1.0)
    ///   - bitCount: Optional explicit bit count (calculated if nil)
    ///   - hashFunctionCount: Optional explicit hash function count (calculated if nil)
    ///
    /// The optimal number of bits and hash functions are calculated based on
    /// capacity and false positive rate if not explicitly provided.
    public init(
        capacity: Int,
        falsePositiveRate: Double = 0.01,
        bitCount: Int? = nil,
        hashFunctionCount: Int? = nil
    ) {
        self.capacity = capacity
        self.falsePositiveRate = max(0.0, min(1.0, falsePositiveRate))
        
        // Calculate optimal bit count: m = -n * ln(p) / (ln(2)^2)
        // where n = capacity, p = false positive rate
        let optimalBitCount = bitCount ?? Int(
            ceil(-Double(capacity) * log(self.falsePositiveRate) / (log(2.0) * log(2.0)))
        )
        
        // Calculate optimal hash function count: k = (m/n) * ln(2)
        // where m = bit count, n = capacity
        let optimalHashCount = hashFunctionCount ?? Int(
            ceil((Double(optimalBitCount) / Double(capacity)) * log(2.0))
        )
        
        self.bitCount = max(1, optimalBitCount)
        self.hashFunctionCount = max(1, min(optimalHashCount, 50)) // Cap at 50 hash functions
        
        // Initialize bit array
        self.bits = Array(repeating: false, count: self.bitCount)
    }
    
    /// Insert an element into the Bloom Filter
    /// - Parameter element: Element to insert (must conform to BloomFilterHashable)
    /// Thread-safe: Can be called concurrently
    public func insert<T: BloomFilterHashable>(_ element: T) {
        lock.lock()
        defer { lock.unlock() }
        
        let hashes = generateHashes(for: element)
        for hash in hashes {
            let index = Int(hash % UInt64(bitCount))
            bits[index] = true
        }
        elementCount += 1
    }
    
    /// Check if an element might be in the Bloom Filter
    /// - Parameter element: Element to check (must conform to BloomFilterHashable)
    /// - Returns: true if element might be in set (could be false positive), false if definitely not
    /// Thread-safe: Can be called concurrently
    ///
    /// **Important**: A return value of `true` means the element *might* be in the set,
    /// but could be a false positive. A return value of `false` means the element is
    /// *definitely* not in the set.
    public func contains<T: BloomFilterHashable>(_ element: T) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        let hashes = generateHashes(for: element)
        for hash in hashes {
            let index = Int(hash % UInt64(bitCount))
            if !bits[index] {
                return false // Definitely not in set
            }
        }
        return true // Might be in set (could be false positive)
    }
    
    /// Generate multiple hash values for an element
    /// - Parameter element: Element to hash
    /// - Returns: Array of hash values
    private func generateHashes<T: BloomFilterHashable>(for element: T) -> [UInt64] {
        let baseHash = element.bloomHash()
        var hashes: [UInt64] = []
        
        // Use double hashing technique: h_i(x) = (h1(x) + i * h2(x)) mod m
        // For simplicity, we'll use a variation with multiple hash seeds
        for i in 0..<hashFunctionCount {
            // Create different hash by combining base hash with index
            let hash1 = baseHash
            let hash2 = baseHash &* UInt64(i + 1) &+ UInt64(i * 17)
            let combinedHash = hash1 &+ hash2 &* UInt64(i + 1)
            hashes.append(combinedHash)
        }
        
        return hashes
    }
    
    /// Calculate the current false positive rate
    /// - Returns: Estimated false positive rate based on current state
    /// Thread-safe: Can be called concurrently
    ///
    /// Formula: (1 - e^(-k * n / m))^k
    /// where k = hash function count, n = element count, m = bit count
    public func estimatedFalsePositiveRate() -> Double {
        lock.lock()
        defer { lock.unlock() }
        
        guard elementCount > 0 && bitCount > 0 else {
            return 0.0
        }
        
        let k = Double(hashFunctionCount)
        let n = Double(elementCount)
        let m = Double(bitCount)
        
        // (1 - e^(-k * n / m))^k
        let exponent = -k * n / m
        let base = 1.0 - exp(exponent)
        return pow(base, k)
    }
    
    /// Get the fill ratio (percentage of bits set to true)
    /// - Returns: Fill ratio from 0.0 to 1.0
    /// Thread-safe: Can be called concurrently
    public func fillRatio() -> Double {
        lock.lock()
        defer { lock.unlock() }
        
        let setBits = bits.filter { $0 }.count
        return Double(setBits) / Double(bitCount)
    }
    
    /// Clear the Bloom Filter (remove all elements)
    /// Thread-safe: Can be called concurrently
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        
        bits = Array(repeating: false, count: bitCount)
        elementCount = 0
    }
    
    /// Merge another Bloom Filter into this one (union operation)
    /// - Parameter other: Bloom Filter to merge
    /// - Throws: BloomFilterError if filters are incompatible
    /// Thread-safe: Can be called concurrently
    ///
    /// Both filters must have the same bit count and hash function count.
    public func merge(_ other: BloomFilter) throws {
        lock.lock()
        defer { lock.unlock() }
        
        guard self.bitCount == other.bitCount else {
            throw BloomFilterError.incompatibleFilters("Bit counts must match")
        }
        
        guard self.hashFunctionCount == other.hashFunctionCount else {
            throw BloomFilterError.incompatibleFilters("Hash function counts must match")
        }
        
        // Perform bitwise OR operation
        other.lock.lock()
        defer { other.lock.unlock() }
        
        for i in 0..<bitCount {
            bits[i] = bits[i] || other.bits[i]
        }
        
        // Update element count (approximate)
        elementCount = max(elementCount, other.elementCount)
    }
}

/// Bloom Filter errors
public enum BloomFilterError: Error {
    case incompatibleFilters(String)
    
    public var localizedDescription: String {
        switch self {
        case .incompatibleFilters(let reason):
            return "Cannot merge Bloom Filters: \(reason)"
        }
    }
}

/// Counting Bloom Filter - A variant that supports element removal
///
/// A Counting Bloom Filter uses counters instead of bits, allowing elements
/// to be removed. This comes at the cost of increased memory usage.
///
/// ## Usage
///
/// ```swift
/// import DesignAlgorithmsKit
///
/// // Create Counting Bloom Filter
/// let filter = CountingBloomFilter(capacity: 1000, falsePositiveRate: 0.01)
///
/// // Add elements
/// filter.insert("element1")
/// filter.insert("element2")
///
/// // Remove elements
/// filter.remove("element1")
///
/// // Check membership
/// if filter.contains("element2") {
///     // Element might be in set
/// }
/// ```
public final class CountingBloomFilter {
    /// Counter array for storing element counts
    private var counters: [UInt8]
    
    /// Number of counters in the filter
    public let counterCount: Int
    
    /// Number of hash functions to use
    public let hashFunctionCount: Int
    
    /// Expected capacity (number of elements)
    public let capacity: Int
    
    /// Target false positive rate
    public let falsePositiveRate: Double
    
    /// Number of elements inserted
    private(set) public var elementCount: Int = 0
    
    /// Lock for thread-safe access
    private let lock = NSLock()
    
    /// Initialize Counting Bloom Filter
    /// - Parameters:
    ///   - capacity: Expected number of elements to be inserted
    ///   - falsePositiveRate: Desired false positive rate (0.0 to 1.0)
    ///   - counterCount: Optional explicit counter count (calculated if nil)
    ///   - hashFunctionCount: Optional explicit hash function count (calculated if nil)
    public init(
        capacity: Int,
        falsePositiveRate: Double = 0.01,
        counterCount: Int? = nil,
        hashFunctionCount: Int? = nil
    ) {
        self.capacity = capacity
        self.falsePositiveRate = max(0.0, min(1.0, falsePositiveRate))
        
        // Calculate optimal counter count (same as bit count for regular Bloom Filter)
        let optimalCounterCount = counterCount ?? Int(
            ceil(-Double(capacity) * log(self.falsePositiveRate) / (log(2.0) * log(2.0)))
        )
        
        // Calculate optimal hash function count
        let optimalHashCount = hashFunctionCount ?? Int(
            ceil((Double(optimalCounterCount) / Double(capacity)) * log(2.0))
        )
        
        self.counterCount = max(1, optimalCounterCount)
        self.hashFunctionCount = max(1, min(optimalHashCount, 50))
        
        // Initialize counter array
        self.counters = Array(repeating: 0, count: self.counterCount)
    }
    
    /// Insert an element into the Counting Bloom Filter
    /// - Parameter element: Element to insert (must conform to BloomFilterHashable)
    /// Thread-safe: Can be called concurrently
    public func insert<T: BloomFilterHashable>(_ element: T) {
        lock.lock()
        defer { lock.unlock() }
        
        let hashes = generateHashes(for: element)
        for hash in hashes {
            let index = Int(hash % UInt64(counterCount))
            if counters[index] < UInt8.max {
                counters[index] += 1
            }
        }
        elementCount += 1
    }
    
    /// Remove an element from the Counting Bloom Filter
    /// - Parameter element: Element to remove (must conform to BloomFilterHashable)
    /// Thread-safe: Can be called concurrently
    ///
    /// **Note**: Removing an element that was never inserted can cause false negatives.
    public func remove<T: BloomFilterHashable>(_ element: T) {
        lock.lock()
        defer { lock.unlock() }
        
        let hashes = generateHashes(for: element)
        for hash in hashes {
            let index = Int(hash % UInt64(counterCount))
            if counters[index] > 0 {
                counters[index] -= 1
            }
        }
        elementCount = max(0, elementCount - 1)
    }
    
    /// Check if an element might be in the Counting Bloom Filter
    /// - Parameter element: Element to check (must conform to BloomFilterHashable)
    /// - Returns: true if element might be in set, false if definitely not
    /// Thread-safe: Can be called concurrently
    public func contains<T: BloomFilterHashable>(_ element: T) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        let hashes = generateHashes(for: element)
        for hash in hashes {
            let index = Int(hash % UInt64(counterCount))
            if counters[index] == 0 {
                return false // Definitely not in set
            }
        }
        return true // Might be in set
    }
    
    /// Generate multiple hash values for an element
    /// - Parameter element: Element to hash
    /// - Returns: Array of hash values
    private func generateHashes<T: BloomFilterHashable>(for element: T) -> [UInt64] {
        let baseHash = element.bloomHash()
        var hashes: [UInt64] = []
        
        for i in 0..<hashFunctionCount {
            let hash1 = baseHash
            let hash2 = baseHash &* UInt64(i + 1) &+ UInt64(i * 17)
            let combinedHash = hash1 &+ hash2 &* UInt64(i + 1)
            hashes.append(combinedHash)
        }
        
        return hashes
    }
    
    /// Clear the Counting Bloom Filter (remove all elements)
    /// Thread-safe: Can be called concurrently
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        
        counters = Array(repeating: 0, count: counterCount)
        elementCount = 0
    }
}
#endif

