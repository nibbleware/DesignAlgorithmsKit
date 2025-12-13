//
//  Iterator.swift
//  DesignAlgorithmsKit
//
//  Iterator Pattern - Access elements of a collection consistently
//

import Foundation

/// Protocol for iterators
public protocol Iterator {
    associatedtype Element
    
    /// Check if there are more elements
    func hasNext() -> Bool
    
    /// Get the next element
    func next() -> Element?
}

/// Protocol for iterable aggregates
public protocol Iterable {
    associatedtype IteratorType: Iterator
    
    /// Create an iterator
    func makeIterator() -> IteratorType
}

/// A concrete iterator for array-based collections
public class ArrayIterator<T>: Iterator {
    private let items: [T]
    private var currentIndex = 0
    
    public init(_ items: [T]) {
        self.items = items
    }
    
    public func hasNext() -> Bool {
        return currentIndex < items.count
    }
    
    public func next() -> T? {
        guard hasNext() else { return nil }
        let item = items[currentIndex]
        currentIndex += 1
        return item
    }
}

/// A concrete iterator for tree structures (depth-first)
public class TreeIterator<T>: Iterator {
    private var stack: [T] = []
    private let getChildren: (T) -> [T]
    
    public init(root: T, getChildren: @escaping (T) -> [T]) {
        self.stack = [root]
        self.getChildren = getChildren
    }
    
    public func hasNext() -> Bool {
        return !stack.isEmpty
    }
    
    public func next() -> T? {
        guard !stack.isEmpty else { return nil }
        let current = stack.removeLast()
        // Add children to stack in reverse order to process them in original order
        let children = getChildren(current)
        for child in children.reversed() {
            stack.append(child)
        }
        return current
    }
}
