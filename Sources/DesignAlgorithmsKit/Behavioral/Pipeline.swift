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
