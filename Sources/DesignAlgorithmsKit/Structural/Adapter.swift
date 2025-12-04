//
//  Adapter.swift
//  DesignAlgorithmsKit
//
//  Adapter Pattern - Convert the interface of a class into another interface clients expect
//

import Foundation

/// Protocol for adapter implementations
///
/// Adapters convert the interface of a class into another interface that clients expect.
/// This allows classes with incompatible interfaces to work together.
public protocol Adapter {
    /// Adapter identifier
    var adapterID: String { get }
    
    /// Check if adapter can handle the given input
    /// - Parameter input: Input to check
    /// - Returns: true if adapter can handle input
    func canHandle(_ input: Any) -> Bool
}

/// Base adapter implementation
///
/// Provides a base implementation for adapter pattern. Adapters wrap
/// or adapt existing types to new interfaces.
///
/// ## Usage
///
/// ```swift
/// protocol Target {
///     func request() -> String
/// }
///
/// class Adaptee {
///     func specificRequest() -> String {
///         return "Adaptee"
///     }
/// }
///
/// class AdapteeAdapter: BaseAdapter, Target {
///     private let adaptee: Adaptee
///
///     init(adaptee: Adaptee) {
///         self.adaptee = adaptee
///         super.init(adapterID: "adapteeAdapter")
///     }
///
///     func request() -> String {
///         return adaptee.specificRequest()
///     }
///
///     override func canHandle(_ input: Any) -> Bool {
///         return input is Adaptee
///     }
/// }
/// ```
open class BaseAdapter: Adapter {
    public let adapterID: String
    
    public init(adapterID: String) {
        self.adapterID = adapterID
    }
    
    open func canHandle(_ input: Any) -> Bool {
        return false
    }
}

