//
//  Composite.swift
//  DesignAlgorithmsKit
//
//  Composite Pattern - Compose objects into tree structures to represent part-whole hierarchies
//

import Foundation

/// Protocol for components in the composite structure
public protocol Component: AnyObject {
    /// The parent of this component
    var parent: Component? { get set }
    
    /// Execute an operation on the component
    func operation()
    
    /// Add a child component (optional operation)
    func add(_ component: Component)
    
    /// Remove a child component (optional operation)
    func remove(_ component: Component)
    
    /// Get a child component by index (optional operation)
    func getChild(at index: Int) -> Component?
}

/// Base implementation of a component providing default behavior
open class BaseComponent: Component {
    public weak var parent: Component?
    
    public init() {}
    
    open func operation() {
        // Default implementation does nothing
    }
    
    open func add(_ component: Component) {
        // Default: leaf nodes can't add children
    }
    
    open func remove(_ component: Component) {
        // Default: leaf nodes can't remove children
    }
    
    open func getChild(at index: Int) -> Component? {
        return nil
    }
}

/// A leaf component in the tree (has no children)
open class Leaf: BaseComponent {
    open override func operation() {
        // Perform leaf-specific operation
    }
}

/// A composite component that can contain children
open class Composite: BaseComponent {
    private var children: [Component] = []
    
    open override func operation() {
        // Execute operation on all children
        for child in children {
            child.operation()
        }
    }
    
    open override func add(_ component: Component) {
        children.append(component)
        component.parent = self
    }
    
    open override func remove(_ component: Component) {
        children.removeAll { $0 === component }
        if component.parent === self {
            component.parent = nil
        }
    }
    
    open override func getChild(at index: Int) -> Component? {
        guard index >= 0 && index < children.count else { return nil }
        return children[index]
    }
    
    /// Get all children
    public func getChildren() -> [Component] {
        return children
    }
}
