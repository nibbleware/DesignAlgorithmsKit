import XCTest
@testable import DesignAlgorithmsKit

@available(macOS 12.0, iOS 15.0, *)
final class ResourceCoordinatorTests: XCTestCase {
    
    // MARK: - Integration Tests
    
    func testConcurrentReads() async throws {
        let coordinator = ResourceCoordinator()
        let path = "test/file.txt"
        
        let counter = Counter()
        
        // Launch 10 concurrent readers
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    try? await coordinator.access(path: path, type: .read) {
                         try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                         await counter.increment()
                    }
                }
            }
        }
        
        // Assert all 10 ran
        let count = await counter.value
        XCTAssertEqual(count, 10)
    }
    
    func testWriteExclusivity() async throws {
        let coordinator = ResourceCoordinator()
        let path = "test/shared.txt"
        let state = SharedState()
        
        let writeExp = expectation(description: "Write finished")
        let readExp = expectation(description: "Read finished")
        
        Task {
            try await coordinator.access(path: path, type: .write) {
                await state.set(100)
                try await Task.sleep(nanoseconds: 200_000_000) // 200ms
                await state.set(200)
            }
            writeExp.fulfill()
        }
        
        // Delay slightly to ensure writer enters lock
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        Task {
            let val = try await coordinator.access(path: path, type: .read) {
                return await state.value
            }
            XCTAssertEqual(val, 200, "Reader should have waited for writer to finish")
            readExp.fulfill()
        }
        
        await fulfillment(of: [writeExp, readExp], timeout: 2.0)
    }
    
    // MARK: - Helpers
    
    actor Counter {
        var value = 0
        func increment() { value += 1 }
    }
    
    actor SharedState {
        var value = 0
        func set(_ v: Int) { value = v }
    }
}
