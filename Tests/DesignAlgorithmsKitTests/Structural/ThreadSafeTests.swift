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
    

}
