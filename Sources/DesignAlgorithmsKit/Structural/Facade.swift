//
//  Facade.swift
//  DesignAlgorithmsKit
//
//  Facade Pattern - Provide a simplified interface to a complex subsystem
//

import Foundation

/// Protocol for facade implementations
///
/// Facades provide a simplified interface to complex subsystems, hiding
/// implementation details and making the subsystem easier to use.
public protocol Facade {
    /// Facade identifier
    var facadeID: String { get }
}

/// Base facade implementation
///
/// Provides a base implementation for facade pattern. Facades delegate
/// to internal implementations while providing a stable public API.
///
/// ## Usage
///
/// ```swift
/// protocol MySubsystemFacade: Facade {
///     func performOperation() async throws -> Result
/// }
///
/// struct MyFacade: MySubsystemFacade {
///     let facadeID = "myFacade"
///     private let implementation: InternalImplementation
///
///     init(implementation: InternalImplementation) {
///         self.implementation = implementation
///     }
///
///     func performOperation() async throws -> Result {
///         // Delegate to internal implementation
///         return try await implementation.performComplexOperation()
///     }
/// }
/// ```
open class BaseFacade: Facade {
    public let facadeID: String
    
    public init(facadeID: String) {
        self.facadeID = facadeID
    }
}

