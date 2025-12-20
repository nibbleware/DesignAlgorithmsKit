import XCTest
@testable import DesignAlgorithmsKit

final class PipelineTests: XCTestCase {
    
    // MARK: - Synchronous Pipeline Tests
    
    func testSyncPipelineExecution() throws {
        let pipeline = DataPipeline<Int, String> { input in
            return String(input)
        }
        
        let result = try pipeline.execute(123)
        XCTAssertEqual(result, "123")
    }
    
    func testSyncPipelineChaining() throws {
        let pipeline = DataPipeline<Int, Int> { input in
            return input * 2
        }
        .appending { input in
            return input + 10
        }
        .appending { input in
            return String(input)
        }
        
        let result = try pipeline.execute(5)
        // (5 * 2) + 10 = 20 -> "20"
        XCTAssertEqual(result, "20")
    }
    
    struct IntToStringStage: DataPipelineStage {
        func process(_ input: Int) throws -> String {
            return String(input)
        }
    }
    
    func testSyncPipelineWithStageObject() throws {
        let pipeline = DataPipeline<Int, Int> { $0 * 2 }
            .appending(IntToStringStage())
        
        let result = try pipeline.execute(5)
        XCTAssertEqual(result, "10")
    }
    
    
    func testSyncPipelineErrorPropagation() {
        let pipeline = DataPipeline<Int, Int> { _ in
            throw PipelineError.stageFailure(stageIndex: 0, underlyingError: NSError(domain: "test", code: 1))
        }
        .appending { $0 + 1 }
        
        XCTAssertThrowsError(try pipeline.execute(1)) { error in
            if case let PipelineError.stageFailure(index, _) = error {
                XCTAssertEqual(index, 0)
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    func testSyncPipelineMidChainFailure() {
        let pipeline = DataPipeline<Int, Int> { $0 * 2 }
            .appending { val -> Int in
                if val == 4 { throw PipelineError.stageFailure(stageIndex: 1, underlyingError: NSError(domain: "test", code: 1)) }
                return val
            }
            .appending { String($0) }
            
        // Should succeed
        XCTAssertNoThrow(try pipeline.execute(1)) // 1 -> 2 -> "2"
        
        // Should fail
        XCTAssertThrowsError(try pipeline.execute(2)) // 2 -> 4 -> Error
    }
    
    // MARK: - Asynchronous Pipeline Tests
    
    func testAsyncPipelineExecution() async throws {
        let pipeline = AsyncDataPipeline<Int, String> { input in
            try await Task.sleep(nanoseconds: 1_000_000)
            return String(input)
        }
        
        let result = try await pipeline.execute(123)
        XCTAssertEqual(result, "123")
    }
    
    func testAsyncPipelineChaining() async throws {
        let pipeline = AsyncDataPipeline<Int, Int> { input in
            return input * 2
        }
        .appending { input in
            return input + 10
        }
        .appending { input in
            return String(input)
        }
        
        let result = try await pipeline.execute(5)
        XCTAssertEqual(result, "20")
    }
    
    struct IntToStringAsyncStage: AsyncDataPipelineStage {
        func process(_ input: Int) async throws -> String {
            return String(input)
        }
    }
    
    func testAsyncPipelineWithStageObject() async throws {
        let pipeline = AsyncDataPipeline<Int, Int> { $0 * 2 }
            .appending(IntToStringAsyncStage())
        
        let result = try await pipeline.execute(5)
        XCTAssertEqual(result, "10")
    }
    
    func testAsyncPipelineErrorPropagation() async {
        let pipeline = AsyncDataPipeline<Int, Int> { _ in
            throw PipelineError.stageFailure(stageIndex: 0, underlyingError: NSError(domain: "test", code: 1))
        }
        
        do {
            _ = try await pipeline.execute(1)
            XCTFail("Should have thrown error")
        } catch {
            if case let PipelineError.stageFailure(index, _) = error {
                XCTAssertEqual(index, 0)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    // MARK: - Dynamic Pipeline Tests
    
    func testDynamicAsyncPipeline() async throws {
        let pipeline = DynamicAsyncPipeline()
        
        let stage1 = AnyAsyncPipelineStage(process: { (input: Any) async throws -> Any in
            guard let intInput = input as? Int else { throw PipelineError.invalidInputType(expected: "Int", actual: String(describing: type(of: input))) }
            return intInput * 2
        })
        
        let stage2 = AnyAsyncPipelineStage(process: { (input: Any) async throws -> Any in
            guard let intInput = input as? Int else { throw PipelineError.invalidInputType(expected: "Int", actual: String(describing: type(of: input))) }
            return String(intInput)
        })
        
        pipeline.append(stage1)
        pipeline.append(stage2)
        
        let result = try await pipeline.execute(input: 10)
        
        XCTAssertEqual(result as? String, "20")
    }
    
    func testDynamicAsyncPipelineWithTypedStage() async throws {
        let pipeline = DynamicAsyncPipeline()
        pipeline.append(IntToStringAsyncStage()) // Typed stage
        
        let result = try await pipeline.execute(input: 50)
        XCTAssertEqual(result as? String, "50")
    }
    
    func testDynamicAsyncPipelineTypeMismatch() async {
        let pipeline = DynamicAsyncPipeline()
        pipeline.append(IntToStringAsyncStage())
        
        do {
            _ = try await pipeline.execute(input: "NotAnInt")
            XCTFail("Should fail due to type mismatch")
        } catch {
            if case let PipelineError.stageFailure(_, underlyingError) = error,
               case PipelineError.invalidInputType = underlyingError {
                // Success
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
    
    func testRefinedErrorDescription() {
        let error1 = PipelineError.invalidInputType(expected: "Int", actual: "String")
        XCTAssertEqual(error1.localizedDescription, "Pipeline stage expected input of type 'Int' but received 'String'.")
        
        let underlying = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Underlying fail"])
        let error2 = PipelineError.stageFailure(stageIndex: 2, underlyingError: underlying)
        XCTAssertEqual(error2.localizedDescription, "Pipeline execution failed at stage 2: Underlying fail")
    }
}
