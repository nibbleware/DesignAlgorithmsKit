//
//  Pipeline.swift
//  DesignAlgorithmsKit
//
//  Pipeline Pattern - Process data through a sequence of stages
//

import Foundation

/// Protocol for a pipeline stage
public protocol DataPipelineStage {
    /// The input type for this stage
    associatedtype Input
    
    /// The output type for this stage
    associatedtype Output
    
    /// Process the input and produce output
    /// - Parameter input: Input data
    /// - Returns: Processed output
    /// - Throws: Error if processing fails
    func process(_ input: Input) throws -> Output
}

/// Protocol for an asynchronous pipeline stage
public protocol AsyncDataPipelineStage {
    /// The input type for this stage
    associatedtype Input
    
    /// The output type for this stage
    associatedtype Output
    
    /// Process the input asynchronously
    /// - Parameter input: Input data
    /// - Returns: Processed output
    /// - Throws: Error if processing fails
    func process(_ input: Input) async throws -> Output
}

/// A pipeline that executes stages sequentially
///
/// The pipeline pattern allows processing data through a sequence of stages,
/// where the output of one stage becomes the input of the next.
open class DataPipeline<Input, Output> {
    private let operation: (Input) throws -> Output
    
    /// Initialize with a processing function
    public init(_ operation: @escaping (Input) throws -> Output) {
        self.operation = operation
    }
    
    /// Execute the pipeline
    public func execute(_ input: Input) throws -> Output {
        return try operation(input)
    }
    
    /// Append a new stage to the pipeline
    public func appending<S: DataPipelineStage>(_ stage: S) -> DataPipeline<Input, S.Output> where S.Input == Output {
        return DataPipeline<Input, S.Output> { input in
            let intermediate = try self.execute(input)
            return try stage.process(intermediate)
        }
    }
    
    /// Append a closure stage
    public func appending<NewOutput>(_ closure: @escaping (Output) throws -> NewOutput) -> DataPipeline<Input, NewOutput> {
        return DataPipeline<Input, NewOutput> { input in
            let intermediate = try self.execute(input)
            return try closure(intermediate)
        }
    }
}

/// An asynchronous pipeline
open class AsyncDataPipeline<Input, Output> {
    private let operation: (Input) async throws -> Output
    
    public init(_ operation: @escaping (Input) async throws -> Output) {
        self.operation = operation
    }
    
    public func execute(_ input: Input) async throws -> Output {
        return try await operation(input)
    }
    
    public func appending<S: AsyncDataPipelineStage>(_ stage: S) -> AsyncDataPipeline<Input, S.Output> where S.Input == Output {
        return AsyncDataPipeline<Input, S.Output> { input in
            let intermediate = try await self.execute(input)
            return try await stage.process(intermediate)
        }
    }
    
    public func appending<NewOutput>(_ closure: @escaping (Output) async throws -> NewOutput) -> AsyncDataPipeline<Input, NewOutput> {
        return AsyncDataPipeline<Input, NewOutput> { input in
            let intermediate = try await self.execute(input)
            return try await closure(intermediate)
        }
    }
}

// MARK: - Type-Erased Pipelines (AnyPipeline)

/// A type-erased async pipeline stage that operates on Any input/output.
/// Useful for dynamic pipelines where stages are assembled at runtime.
public struct AnyAsyncPipelineStage: AsyncDataPipelineStage {
    public typealias Input = Any
    public typealias Output = Any
    
    private let _process: (Any) async throws -> Any
    
    public init<S: AsyncDataPipelineStage>(_ stage: S) {
        self._process = { input in
            guard let typedInput = input as? S.Input else {
                throw PipelineError.invalidInputType(expected: String(describing: S.Input.self), actual: String(describing: type(of: input)))
            }
            return try await stage.process(typedInput)
        }
    }
    
    public init(process: @escaping (Any) async throws -> Any) {
        self._process = process
    }
    
    public func process(_ input: Any) async throws -> Any {
        return try await _process(input)
    }
}

/// Errors thrown by the pipeline
public enum PipelineError: Error, LocalizedError {
    case invalidInputType(expected: String, actual: String)
    case stageFailure(stageIndex: Int, underlyingError: Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidInputType(let expected, let actual):
            return "Pipeline stage expected input of type '\(expected)' but received '\(actual)'."
        case .stageFailure(let index, let error):
            return "Pipeline execution failed at stage \(index): \(error.localizedDescription)"
        }
    }
}

/// A pipeline builder that chains type-erased stages dynamically.
public class DynamicAsyncPipeline {
    private var stages: [AnyAsyncPipelineStage] = []
    
    public init() {}
    
    public func append(_ stage: AnyAsyncPipelineStage) {
        stages.append(stage)
    }
    
    public func append<S: AsyncDataPipelineStage>(_ stage: S) {
        stages.append(AnyAsyncPipelineStage(stage))
    }
    
    public func execute(input: Any) async throws -> Any {
        var currentData = input
        
        for (index, stage) in stages.enumerated() {
            do {
                currentData = try await stage.process(currentData)
            } catch {
                throw PipelineError.stageFailure(stageIndex: index, underlyingError: error)
            }
        }
        
        return currentData
    }
}
