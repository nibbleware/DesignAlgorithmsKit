//
//  Builder.swift
//  DesignAlgorithmsKit
//
//  Builder Pattern - Construct complex objects step by step with fluent API
//

import Foundation

/// Protocol for objects that can be built using a builder
public protocol Buildable {
    /// Build the object from builder state
    associatedtype Builder: BuilderProtocol where Builder.Product == Self
}

/// Protocol for builder implementations
public protocol BuilderProtocol {
    /// The type of object being built
    associatedtype Product
    
    /// Build the final object
    /// - Returns: Built object
    func build() throws -> Product
}

/// Base builder implementation with common functionality
///
/// The builder pattern provides a fluent API for constructing complex objects.
/// This base class provides common functionality that can be extended.
///
/// ## Usage
///
/// ```swift
/// struct MyObject {
///     let property1: String
///     let property2: Int
/// }
///
/// class MyObjectBuilder: BaseBuilder<MyObject> {
///     private var property1: String?
///     private var property2: Int?
///
///     func setProperty1(_ value: String) -> Self {
///         var builder = self
///         builder.property1 = value
///         return builder
///     }
///
///     func setProperty2(_ value: Int) -> Self {
///         var builder = self
///         builder.property2 = value
///         return builder
///     }
///
///     override func build() throws -> MyObject {
///         guard let property1 = property1 else {
///             throw BuilderError.missingRequiredProperty("property1")
///         }
///         guard let property2 = property2 else {
///             throw BuilderError.missingRequiredProperty("property2")
///         }
///         return MyObject(property1: property1, property2: property2)
///     }
/// }
///
/// // Usage
/// let object = try MyObjectBuilder()
///     .setProperty1("value")
///     .setProperty2(42)
///     .build()
/// ```
open class BaseBuilder<Product>: BuilderProtocol {
    /// Build the final object
    /// - Returns: Built object
    /// - Throws: BuilderError if build fails
    open func build() throws -> Product {
        throw BuilderError.notImplemented
    }
}

/// Builder errors
public enum BuilderError: Error {
    case notImplemented
    case missingRequiredProperty(String)
    case invalidValue(String, String)
    
    public var localizedDescription: String {
        switch self {
        case .notImplemented:
            return "Builder build() method not implemented"
        case .missingRequiredProperty(let property):
            return "Required property '\(property)' is missing"
        case .invalidValue(let property, let reason):
            return "Invalid value for '\(property)': \(reason)"
        }
    }
}

/// Protocol for builders that support validation
public protocol ValidatingBuilderProtocol {
    /// Validate builder state before building
    /// - Throws: BuilderError if validation fails
    func validate() throws
}

extension ValidatingBuilderProtocol {
    /// Default validation (can be overridden)
    public func validate() throws {
        // Default: no validation
    }
}

