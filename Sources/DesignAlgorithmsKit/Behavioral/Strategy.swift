//
//  Strategy.swift
//  DesignAlgorithmsKit
//
//  Strategy Pattern - Define a family of algorithms, encapsulate each one, and make them interchangeable
//

import Foundation

/// Protocol for strategy implementations
///
/// Strategies define a family of algorithms, encapsulate each one, and make them interchangeable.
/// This allows the algorithm to vary independently from clients that use it.
///
/// ## Usage
///
/// ```swift
/// protocol SortingStrategy: Strategy {
///     func sort<T: Comparable>(_ array: [T]) -> [T]
/// }
///
/// struct QuickSortStrategy: SortingStrategy {
///     func sort<T: Comparable>(_ array: [T]) -> [T] {
///         // Quick sort implementation
///         return array.sorted()
///     }
/// }
///
/// struct MergeSortStrategy: SortingStrategy {
///     func sort<T: Comparable>(_ array: [T]) -> [T] {
///         // Merge sort implementation
///         return array.sorted()
///     }
/// }
///
/// // Usage
/// let context = SortingContext(strategy: QuickSortStrategy())
/// let sorted = context.sort([3, 1, 2])
/// ```
public protocol Strategy {
    /// Strategy identifier
    var strategyID: String { get }
}

/// Base strategy implementation
open class BaseStrategy: Strategy {
    public let strategyID: String
    
    public init(strategyID: String) {
        self.strategyID = strategyID
    }
}

/// Context that uses a strategy
///
/// The context maintains a reference to a strategy object and delegates
/// algorithm execution to the strategy.
open class StrategyContext<StrategyType: Strategy> {
    /// Current strategy
    private var strategy: StrategyType
    
    /// Initialize context with strategy
    /// - Parameter strategy: Strategy to use
    public init(strategy: StrategyType) {
        self.strategy = strategy
    }
    
    /// Set the strategy
    /// - Parameter strategy: New strategy to use
    public func setStrategy(_ strategy: StrategyType) {
        self.strategy = strategy
    }
    
    /// Get current strategy
    /// - Returns: Current strategy
    public func getStrategy() -> StrategyType {
        return strategy
    }
}

