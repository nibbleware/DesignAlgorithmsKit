import XCTest
@testable import DesignAlgorithmsKit

final class ThreadSafeArrayTests: XCTestCase {
    
    // MARK: - Basic Functionality
    
    func testInitialization() {
        let array = ThreadSafeArray<Int>()
        XCTAssertTrue(array.isEmpty)
        XCTAssertEqual(array.count, 0)
        
        let arrayWithItems = ThreadSafeArray([1, 2, 3])
        XCTAssertFalse(arrayWithItems.isEmpty)
        XCTAssertEqual(arrayWithItems.count, 3)
    }
    
    func testAppendAndHelpers() {
        let array = ThreadSafeArray<Int>()
        array.append(1)
        XCTAssertEqual(array.count, 1)
        XCTAssertEqual(array[0], 1)
        
        array.append(contentsOf: [2, 3])
        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array.allElements, [1, 2, 3])
    }
    
    func testRemove() {
        let array = ThreadSafeArray([1, 2, 3])
        
        let removed = array.remove(at: 1)
        XCTAssertEqual(removed, 2)
        XCTAssertEqual(array.count, 2)
        XCTAssertEqual(array.allElements, [1, 3])
        
        array.removeAll()
        XCTAssertTrue(array.isEmpty)
    }
    
    func testSubscriptModifiers() {
        let array = ThreadSafeArray([1, 2, 3])
        XCTAssertEqual(array[0], 1)
        
        array[0] = 10
        XCTAssertEqual(array[0], 10)
    }
    
    func testFunctionalMethods() {
        let array = ThreadSafeArray([1, 2, 3, 4, 5])
        
        // Map
        let stringArray = array.map { String($0) }
        XCTAssertEqual(stringArray, ["1", "2", "3", "4", "5"])
        
        // Filter
        let evenArray = array.filter { $0 % 2 == 0 }
        XCTAssertEqual(evenArray, [2, 4])
        
        // CompactMap
        let optionalArray = ThreadSafeArray(["1", "2", "NaN", "4"])
        let numbers = optionalArray.compactMap { Int($0) }
        XCTAssertEqual(numbers, [1, 2, 4])
        
        // First(where:)
        let firstEven = array.first { $0 % 2 == 0 }
        XCTAssertEqual(firstEven, 2)
        
        // Contains(where:)
        XCTAssertTrue(array.contains { $0 == 3 })
        XCTAssertFalse(array.contains { $0 == 6 })
    }
    
    func testReadWriteBlock() {
        let array = ThreadSafeArray([1, 2, 3])
        
        // Write block
        array.write { elements in
            elements.append(4)
            elements[0] = 99
        }
        
        // Read block
        let sum = array.read { elements in
            return elements.reduce(0, +)
        }
        
        // 99 + 2 + 3 + 4 = 108
        XCTAssertEqual(sum, 108)
    }
    
    // MARK: - Concurrency Stress Tests
    
    func testConcurrentAppendAndRead() {
        let array = ThreadSafeArray<Int>()
        let iterations = 2000 // High iteration count
        let expectation = self.expectation(description: "Concurrent append")
        expectation.expectedFulfillmentCount = iterations
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            // Mix of writes and reads
            array.append(i)
            
            // Randomly read
            if i % 100 == 0 {
                _ = array.count
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10.0)
        
        // Should have all elements
        XCTAssertEqual(array.count, iterations)
    }
    
    func testConcurrentRacesInMap() {
        let array = ThreadSafeArray<Int>()
        // Fill array first
        for i in 0..<100 { array.append(i) }
        
        let expectation = self.expectation(description: "Concurrent map")
        expectation.expectedFulfillmentCount = 10
        
        DispatchQueue.concurrentPerform(iterations: 10) { _ in
            // Simultaneously map (read)
            let _ = array.map { $0 * 2 }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
}
