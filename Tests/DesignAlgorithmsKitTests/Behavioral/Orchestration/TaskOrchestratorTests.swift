import XCTest
@testable import DesignAlgorithmsKit

@available(macOS 12.0, iOS 15.0, *)
final class TaskOrchestratorTests: XCTestCase {
    
    func testLinearDependency() async throws {
        let orchestrator = TaskOrchestrator()
        let result = ResultCollector()
        
        let taskA = DAGTask(id: "A") {
            await result.append("A")
        }
        
        // B depends on A
        let taskB = DAGTask(id: "B", dependencies: ["A"]) {
            await result.append("B")
        }
        
        // C depends on B
        let taskC = DAGTask(id: "C", dependencies: ["B"]) {
            await result.append("C")
        }
        
        await orchestrator.addTask(taskA)
        await orchestrator.addTask(taskB)
        await orchestrator.addTask(taskC)
        
        try await orchestrator.execute()
        
        let order = await result.items
        XCTAssertEqual(order, ["A", "B", "C"])
    }
    
    func testParallelExecution() async throws {
        let orchestrator = TaskOrchestrator()
        let result = ResultCollector()
        
        // A and B independent. C depends on both.
        let taskA = DAGTask(id: "A") {
            try? await Task.sleep(nanoseconds: 10_000_000)
            await result.append("A")
        }
        
        let taskB = DAGTask(id: "B") {
             try? await Task.sleep(nanoseconds: 10_000_000)
             await result.append("B")
        }
        
        let taskC = DAGTask(id: "C", dependencies: ["A", "B"]) {
            await result.append("C")
        }
        
        await orchestrator.addTask(taskA)
        await orchestrator.addTask(taskB)
        await orchestrator.addTask(taskC)
        
        try await orchestrator.execute()
        
        let order = await result.items
        // A and B can be in any order, but both must be before C
        XCTAssertTrue(order.contains("A"))
        XCTAssertTrue(order.contains("B"))
        XCTAssertEqual(order.last, "C")
        XCTAssertEqual(order.count, 3)
    }
    
    func testCycleDetection() async {
        let orchestrator = TaskOrchestrator()
        
        let taskA = DAGTask(id: "A", dependencies: ["B"]) { }
        let taskB = DAGTask(id: "B", dependencies: ["A"]) { }
        
        await orchestrator.addTask(taskA)
        await orchestrator.addTask(taskB)
        
        do {
            try await orchestrator.execute()
            XCTFail("Should have thrown cycle detected error")
        } catch OrchestrationError.cycleDetected {
            // Success
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }
    
    // MARK: - Helpers
    actor ResultCollector {
        var items: [String] = []
        func append(_ item: String) { items.append(item) }
    }
}
