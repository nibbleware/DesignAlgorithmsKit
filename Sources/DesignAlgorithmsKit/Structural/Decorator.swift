//
//  Decorator.swift
//  DesignAlgorithmsKit
//
//  Decorator Pattern - Add responsibilities to objects dynamically
//

import Foundation

/// Protocol for decorators
/// Note: In Swift, extensions and protocol composition often replace the Decorator pattern.
/// However, the classic wrapper pattern is still useful for dynamic composition.
public protocol Decorator {
    associatedtype Component
    
    var component: Component { get }
}

/// Base decorator implementation
open class BaseDecorator<T>: Decorator {
    public let component: T
    
    public init(_ component: T) {
        self.component = component
    }
}

/// Example usage wrapper for protocol objects
/// 
/// ```swift
/// protocol DataService {
///     func fetchData() -> String
/// }
///
/// class LoggingDecorator: BaseDecorator<DataService>, DataService {
///     func fetchData() -> String {
///         print("Fetching data...")
///         let result = component.fetchData()
///         print("Data fetched")
///         return result
///     }
/// }
/// ```
