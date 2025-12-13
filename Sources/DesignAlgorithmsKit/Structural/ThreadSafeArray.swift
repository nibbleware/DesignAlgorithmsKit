// DesignAlgorithmsKit
// Structural Pattern: ThreadSafe Array
//
// A thread-safe wrapper around a standard Swift Array.
// Uses ThreadSafe<[Element]> internally.

import Foundation

/// A thread-safe array wrapper.
/// Provides safe concurrent access to an array using an internal lock.
public final class ThreadSafeArray<Element>: @unchecked Sendable {
    private let storage: ThreadSafe<[Element]>
    
    public init(_ array: [Element] = []) {
        self.storage = ThreadSafe(array)
    }
    
    /// The number of elements in the array.
    public var count: Int {
        storage.read { $0.count }
    }
    
    /// A Boolean value indicating whether the collection is empty.
    public var isEmpty: Bool {
        storage.read { $0.isEmpty }
    }
    
    /// Adds a new element at the end of the array.
    public func append(_ newElement: Element) {
        storage.write { $0.append(newElement) }
    }
    
    /// Adds the elements of a sequence to the end of the array.
    public func append<S>(contentsOf newElements: S) where S : Sequence, Element == S.Element {
        storage.write { $0.append(contentsOf: newElements) }
    }
    
    /// Removes and returns the element at the specified position.
    public func remove(at index: Int) -> Element {
        storage.write { $0.remove(at: index) }
    }
    
    /// Removes all elements from the array.
    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        storage.write { $0.removeAll(keepingCapacity: keepCapacity) }
    }
    
    /// Accesses the element at the specified position.
    /// Note: This is not efficient for iteration. Use `read` or `map` for batch operations.
    public subscript(index: Int) -> Element {
        get {
            storage.read { $0[index] }
        }
        set {
            storage.write { $0[index] = newValue }
        }
    }
    
    /// Returns an array containing the results of mapping the given closure over the sequence’s elements.
    public func map<T>(_ transform: (Element) throws -> T) rethrows -> [T] {
        try storage.read { try $0.map(transform) }
    }
    
    /// Returns an array containing the non-nil results of calling the given transformation with each element of this sequence.
    public func compactMap<T>(_ transform: (Element) throws -> T?) rethrows -> [T] {
        try storage.read { try $0.compactMap(transform) }
    }
    
    /// Returns an array containing, in order, the elements of the sequence that satisfy the given predicate.
    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> [Element] {
        try storage.read { try $0.filter(isIncluded) }
    }
    
    /// Returns the first element of the sequence that satisfies the given predicate.
    public func first(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        try storage.read { try $0.first(where: predicate) }
    }
    
    /// Returns a Boolean value indicating whether the sequence contains an element that satisfies the given predicate.
    public func contains(where predicate: (Element) throws -> Bool) rethrows -> Bool {
        try storage.read { try $0.contains(where: predicate) }
    }
    
    /// Returns a new array containing the elements of this array.
    public var allElements: [Element] {
        storage.read { $0 }
    }
    
    /// Execute a block with the array for reading
    public func read<Result>(_ block: ([Element]) throws -> Result) rethrows -> Result {
        try storage.read(block)
    }
    
    /// Execute a block with the array for writing
    public func write<Result>(_ block: (inout [Element]) throws -> Result) rethrows -> Result {
        try storage.write(block)
    }
}
