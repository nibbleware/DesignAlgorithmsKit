//
//  Registry.swift
//  DesignAlgorithmsKit
//
//  Registry Pattern - Centralized registration and discovery of extensible types
//

import Foundation

/// Protocol for types that can be registered in a registry
public protocol Registrable {
    /// Unique key for registration
    static var registrationKey: String { get }
}

/// Thread-safe registry for type registration and discovery
///
/// The registry pattern provides a centralized way to register and discover types
/// at runtime. This enables extensibility and plugin-like architectures.
///
/// ## Usage
///
/// ```swift
/// // Register a type
/// TypeRegistry.shared.register(MyType.self, key: "myType")
///
/// // Find registered type
/// if let type = TypeRegistry.shared.find(for: "myType") {
///     // Use type
/// }
/// ```
///
/// ## Thread Safety
///
/// All operations are thread-safe using NSLock for synchronization.
public final class TypeRegistry: @unchecked Sendable {
    /// Shared singleton instance (lazy initialization to avoid static initialization order issues)
    // Protected by lock, so marked as nonisolated(unsafe) for concurrency safety
    nonisolated(unsafe) private static var _shared: TypeRegistry?
    nonisolated private static let lock = NSLock()
    
    /// Shared singleton instance (lazy)
    public static var shared: TypeRegistry {
        lock.lock()
        defer { lock.unlock() }
        if _shared == nil {
            _shared = TypeRegistry()
        }
        return _shared!
    }
    
    /// Lock for thread-safe access
    private let lock = NSLock()
    
    /// Registered types (key -> type)
    private var registeredTypes: [String: Any.Type] = [:]
    
    private init() {
        // Private initializer for singleton
    }
    
    /// Register a type
    /// - Parameter type: The type to register
    /// - Parameter key: Optional custom key (defaults to type name)
    /// Thread-safe: Can be called concurrently
    public func register(_ type: Any.Type, key: String? = nil) {
        lock.lock()
        defer { lock.unlock() }
        
        let registrationKey = key ?? String(describing: type)
        registeredTypes[registrationKey] = type
    }
    
    /// Register a type conforming to Registrable protocol
    /// - Parameter type: The registrable type
    /// Thread-safe: Can be called concurrently
    public func register<T: Registrable>(_ type: T.Type) {
        lock.lock()
        defer { lock.unlock() }
        let key = T.registrationKey
        registeredTypes[key] = type
    }
    
    /// Find a registered type
    /// - Parameter key: Key to look up
    /// - Returns: Registered type, or nil if not found
    /// Thread-safe: Can be called concurrently
    public func find(for key: String) -> Any.Type? {
        lock.lock()
        defer { lock.unlock() }
        return registeredTypes[key]
    }
    
    /// Get all registered types
    /// - Returns: Dictionary of all registered types
    /// Thread-safe: Can be called concurrently
    public func allTypes() -> [String: Any.Type] {
        lock.lock()
        defer { lock.unlock() }
        return registeredTypes
    }
    
    /// Check if a type is registered
    /// - Parameter key: Key to check
    /// - Returns: true if type is registered
    /// Thread-safe: Can be called concurrently
    public func isRegistered(key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return registeredTypes[key] != nil
    }
    
    /// Clear all registered types (primarily for testing)
    /// Thread-safe: Can be called concurrently
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        registeredTypes.removeAll()
    }
}

