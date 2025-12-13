import XCTest
@testable import DesignAlgorithmsKit

final class GenericRegistryTests: XCTestCase {
    
    func testRegistration() {
        let registry = Registry<String, Int>()
        
        registry.register(1, for: "one")
        XCTAssertEqual(registry.get("one"), 1)
        
        registry.register(2, for: "two")
        XCTAssertEqual(registry.get("two"), 2)
    }
    
    func testOverwrite() {
        let registry = Registry<String, Int>()
        
        registry.register(1, for: "key")
        XCTAssertEqual(registry.get("key"), 1)
        
        registry.register(2, for: "key")
        XCTAssertEqual(registry.get("key"), 2)
    }
    
    func testRemoval() {
        let registry = Registry<String, Int>()
        registry.register(1, for: "one")
        
        registry.unregister("one")
        XCTAssertNil(registry.get("one"))
        
        registry.register(2, for: "two")
        registry.removeAll()
        XCTAssertNil(registry.get("two"))
    }
    
    func testAll() {
        let registry = Registry<String, Int>()
        registry.register(1, for: "one")
        registry.register(2, for: "two")
        
        let allValues = registry.all()
        XCTAssertEqual(allValues.count, 2)
        XCTAssertTrue(allValues.contains(1))
        XCTAssertTrue(allValues.contains(2))
    }
    
    func testConcurrency() {
        let registry = Registry<Int, Int>()
        let iterations = 1000
        let expectation = self.expectation(description: "Concurrent registry access")
        expectation.expectedFulfillmentCount = iterations
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            registry.register(i, for: i)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        // Count via iteration or if there is a count property (Registry usually doesn't expose count directly but has all().count)
        XCTAssertEqual(registry.all().count, iterations)
        
        // Verify random element
        XCTAssertEqual(registry.get(500), 500)
    }
}
