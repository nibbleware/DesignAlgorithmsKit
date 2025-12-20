import XCTest
@testable import DesignAlgorithmsKit

final class ThreadSafeTests: XCTestCase {
    
    func testInitialization() {
        let safeInt = ThreadSafe(0)
        XCTAssertEqual(safeInt.read { $0 }, 0)
    }
    
    func testReadWrite() {
        let safeInt = ThreadSafe(0)
        
        // Write
        safeInt.write { $0 = 10 }
        
        // Read
        let val = safeInt.read { $0 }
        XCTAssertEqual(val, 10)
    }
    
    func testConcurrency() {
        let safeCounter = ThreadSafe(0)
        let iterations = 1000
        let expectation = self.expectation(description: "Concurrent increment")
        expectation.expectedFulfillmentCount = iterations
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            safeCounter.write { $0 += 1 }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(safeCounter.read { $0 }, iterations)
    }
    
    func testRawValueAccess() {
        let safeInt = ThreadSafe(100)
        
        // Getter
        XCTAssertEqual(safeInt.rawValue, 100)
        
        // Setter
        safeInt.rawValue = 200
        XCTAssertEqual(safeInt.read{ $0 }, 200)
        
        // Setter works with lock
        let group = DispatchGroup()
        for i in 0..<100 {
            group.enter()
            DispatchQueue.global().async {
                safeInt.rawValue = i
                group.leave()
            }
        }
        group.wait()
    }
}
