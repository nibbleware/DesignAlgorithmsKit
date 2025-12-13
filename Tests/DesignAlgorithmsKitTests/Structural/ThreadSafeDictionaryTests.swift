import XCTest
@testable import DesignAlgorithmsKit

final class ThreadSafeDictionaryTests: XCTestCase {
    
    func testInitialization() {
        let dict = ThreadSafeDictionary<String, Int>()
        XCTAssertTrue(dict.isEmpty)
        XCTAssertEqual(dict.count, 0)
        
        let dictWithItems = ThreadSafeDictionary(["a": 1, "b": 2])
        XCTAssertFalse(dictWithItems.isEmpty)
        XCTAssertEqual(dictWithItems.count, 2)
    }
    
    func testSubscript() {
        let dict = ThreadSafeDictionary<String, Int>()
        
        // Write
        dict["a"] = 1
        XCTAssertEqual(dict["a"], 1)
        XCTAssertEqual(dict.count, 1)
        
        // Update
        dict["a"] = 2
        XCTAssertEqual(dict["a"], 2)
        
        // Remove via subscript
        dict["a"] = nil
        XCTAssertNil(dict["a"])
        XCTAssertTrue(dict.isEmpty)
    }
    
    func testDefaultSubscript() {
        let dict = ThreadSafeDictionary<String, Int>()
        
        // Read with default
        XCTAssertEqual(dict["a", default: 0], 0)
        
        // Write with default (modify)
        dict["a", default: 0] += 1
        XCTAssertEqual(dict["a"], 1)
        
        // Verify it persists
        XCTAssertEqual(dict["a"], 1)
    }
    
    func testUpdateValue() {
        let dict = ThreadSafeDictionary<String, Int>()
        
        // Insert new
        let oldVal1 = dict.updateValue(1, forKey: "a")
        XCTAssertNil(oldVal1)
        XCTAssertEqual(dict["a"], 1)
        
        // Update existing
        let oldVal2 = dict.updateValue(2, forKey: "a")
        XCTAssertEqual(oldVal2, 1)
        XCTAssertEqual(dict["a"], 2)
    }
    
    func testRemoveValue() {
        let dict = ThreadSafeDictionary(["a": 1])
        
        let removed = dict.removeValue(forKey: "a")
        XCTAssertEqual(removed, 1)
        XCTAssertTrue(dict.isEmpty)
        
        let notFound = dict.removeValue(forKey: "b")
        XCTAssertNil(notFound)
    }
    
    func testProperties() {
        let dict = ThreadSafeDictionary(["a": 1, "b": 2])
        
        XCTAssertEqual(dict.all.count, 2)
        let keys = dict.keys.sorted()
        let values = dict.values.sorted()
        
        XCTAssertEqual(keys, ["a", "b"])
        XCTAssertEqual(values, [1, 2])
        
        dict.removeAll()
        XCTAssertTrue(dict.isEmpty)
    }
    
    func testConcurrency() {
        let dict = ThreadSafeDictionary<Int, Int>()
        let iterations = 2000
        let expectation = self.expectation(description: "Concurrent dictionary access")
        expectation.expectedFulfillmentCount = iterations
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            // Concurrent writes
            dict[i] = i
            
            // Occasional read
            if i % 100 == 0 {
                _ = dict[i]
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10.0)
        
        XCTAssertEqual(dict.count, iterations)
    }
    
    func testConcurrentUpdatesSameKey() {
        let dict = ThreadSafeDictionary<String, Int>(["counter": 0])
        let iterations = 1000
        let expectation = self.expectation(description: "Concurrent increment")
        expectation.expectedFulfillmentCount = iterations
        
        // Attempt to race on same key
        // NOTE: This test doesn't guarantee atomic increment because read & write are separate operations in `dict["counter"] += 1`
        // We must use `write` block for atomic updates.
        
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            dict.write { $0["counter", default: 0] += 1 }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(dict["counter"], iterations)
    }
    
    func testReadWriteBlock() {
        let dict = ThreadSafeDictionary(["a": 1, "b": 2])
        
        // Write block
        dict.write { items in
            items["c"] = 3
        }
        
        XCTAssertEqual(dict.count, 3)
        
        // Read block
        let keys = dict.read { Array($0.keys).sorted() }
        XCTAssertEqual(keys, ["a", "b", "c"])
    }
}
