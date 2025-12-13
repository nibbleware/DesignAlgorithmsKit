//
//  ChainOfResponsibility.swift
//  DesignAlgorithmsKit
//
//  Chain of Responsibility Pattern - Pass requests along a chain of handlers
//

import Foundation

/// Protocol for a handler in the chain
public protocol Handler: AnyObject {
    /// The next handler in the chain
    var nextHandler: Handler? { get set }
    
    /// Handle a request
    /// - Parameter request: The request to handle
    /// - Returns: Result if handled, nil otherwise
    func handle(_ request: Any) -> Any?
}

/// Base implementation of a handler
open class BaseHandler: Handler {
    public var nextHandler: Handler?
    
    public init(next: Handler? = nil) {
        self.nextHandler = next
    }
    
    /// Set the next handler in the chain
    /// - Parameter handler: The next handler
    /// - Returns: The handler that was set (for chaining)
    @discardableResult
    public func setNext(_ handler: Handler) -> Handler {
        self.nextHandler = handler
        return handler
    }
    
    open func handle(_ request: Any) -> Any? {
        if let next = nextHandler {
            return next.handle(request)
        }
        return nil
    }
}

/// A type-safe version of the Chain of Responsibility
public protocol TypedHandler: AnyObject {
    associatedtype Request
    associatedtype Response
    
    var nextHandler: (any TypedHandler)? { get set }
    
    func handle(_ request: Request) -> Response?
}

/// Base implementation for typed handlers
open class BaseTypedHandler<T, R>: TypedHandler {
    public typealias Request = T
    public typealias Response = R
    
    // We use a type-erased wrapper or force cast internally because generic protocols as types are tricky
    // For simplicity in this generic pattern library, we'll store specific typed handler
    public var nextTypedHandler: BaseTypedHandler<T, R>?
    
    // Conformance to protocol (computed property due to associatedtype limits)
    public var nextHandler: (any TypedHandler)? {
        get { return nextTypedHandler }
        set { nextTypedHandler = newValue as? BaseTypedHandler<T, R> }
    }
    
    public init() {}
    
    @discardableResult
    public func setNext(_ handler: BaseTypedHandler<T, R>) -> BaseTypedHandler<T, R> {
        self.nextTypedHandler = handler
        return handler
    }
    
    open func handle(_ request: T) -> R? {
        return nextTypedHandler?.handle(request)
    }
}
