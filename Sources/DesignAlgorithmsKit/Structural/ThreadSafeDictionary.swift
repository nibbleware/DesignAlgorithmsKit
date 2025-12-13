// DesignAlgorithmsKit
// Structural Pattern: ThreadSafe Dictionary
//
// A thread-safe wrapper around a standard Swift Dictionary.
// Uses ThreadSafe<[Key: Value]> internally.

import Foundation

/// A thread-safe dictionary wrapper.
/// Provides safe concurrent access to a dictionary using an internal lock.
public final class ThreadSafeDictionary<Key: Hashable, Value>: @unchecked Sendable {
    private let storage: ThreadSafe<[Key: Value]>
    
    public init(_ dictionary: [Key: Value] = [:]) {
        self.storage = ThreadSafe(dictionary)
    }
    
    /// The number of key-value pairs in the dictionary.
    public var count: Int {
        storage.read { $0.count }
    }
    
    /// A Boolean value indicating whether the dictionary is empty.
    public var isEmpty: Bool {
        storage.read { $0.isEmpty }
    }
    
    /// Accesses the value associated with the given key for reading and writing.
    public subscript(key: Key) -> Value? {
        get {
            storage.read { $0[key] }
        }
        set {
            storage.write { $0[key] = newValue }
        }
    }
    
    /// Accesses the value with the given key. If the dictionary doesn’t contain the given key, accesses the provided default value as if the key and default value existed in the dictionary.
    public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        get {
            storage.read { $0[key, default: defaultValue()] }
        }
        set {
            storage.write { $0[key, default: defaultValue()] = newValue }
        }
    }
    
    /// Updates the value stored in the dictionary for the given key, or adds a new key-value pair if the key does not exist.
    public func updateValue(_ value: Value, forKey key: Key) -> Value? {
        storage.write { $0.updateValue(value, forKey: key) }
    }
    
    /// Removes the value associated with the given key.
    public func removeValue(forKey key: Key) -> Value? {
        storage.write { $0.removeValue(forKey: key) }
    }
    
    /// Removes all key-value pairs from the dictionary.
    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        storage.write { $0.removeAll(keepingCapacity: keepCapacity) }
    }
    
    /// Returns a new dictionary containing the keys and values of this dictionary.
    public var all: [Key: Value] {
        storage.read { $0 }
    }
    
    /// Returns a collection containing just the keys of the dictionary.
    public var keys: [Key] {
        storage.read { Array($0.keys) }
    }
    
    /// Returns a collection containing just the values of the dictionary.
    public var values: [Value] {
        storage.read { Array($0.values) }
    }
    
    /// Execute a block with the dictionary for reading
    public func read<Result>(_ block: ([Key: Value]) throws -> Result) rethrows -> Result {
        try storage.read(block)
    }
    
    /// Execute a block with the dictionary for writing
    public func write<Result>(_ block: (inout [Key: Value]) throws -> Result) rethrows -> Result {
        try storage.write(block)
    }
}
