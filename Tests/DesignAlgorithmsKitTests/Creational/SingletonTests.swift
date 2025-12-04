//
//  SingletonTests.swift
//  DesignAlgorithmsKitTests
//
//  Unit tests for Singleton Pattern
//

import XCTest
@testable import DesignAlgorithmsKit

final class SingletonTests: XCTestCase {
    
    // MARK: - ThreadSafeSingleton Tests
    
    func testThreadSafeSingletonSingleInstance() {
        // Given - Using a unique class name to avoid static storage conflicts
        class UniqueTestSingleton1: ThreadSafeSingleton {
            var value: String = "initial"
            
            private override init() {
                super.init()
            }
            
            override class func createShared() -> Self {
                // Use a unique static storage per class
                struct StaticStorage {
                    static var instance: UniqueTestSingleton1?
                }
                if StaticStorage.instance == nil {
                    StaticStorage.instance = UniqueTestSingleton1()
                }
                return StaticStorage.instance! as! Self
            }
        }
        
        // When
        let instance1 = UniqueTestSingleton1.shared
        let instance2 = UniqueTestSingleton1.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2, "Should return the same instance")
        XCTAssertEqual(instance1.value, "initial")
    }
    
    func testThreadSafeSingletonThreadSafety() {
        // Given
        class TestSingleton: ThreadSafeSingleton {
            var counter: Int = 0
            
            private override init() {
                super.init()
            }
            
            override class func createShared() -> Self {
                return TestSingleton() as! Self
            }
            
            func increment() {
                counter += 1
            }
        }
        
        // When - Access from multiple threads
        let expectation = expectation(description: "Thread safety test")
        expectation.expectedFulfillmentCount = 10
        
        for _ in 0..<10 {
            DispatchQueue.global().async {
                let instance = TestSingleton.shared
                instance.increment()
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
        
        // Then - Should still be the same instance
        let instance1 = TestSingleton.shared
        let instance2 = TestSingleton.shared
        XCTAssertTrue(instance1 === instance2, "Should return the same instance across threads")
    }
    
    func testThreadSafeSingletonState() {
        // Given
        class TestSingleton: ThreadSafeSingleton {
            var state: String = "initial"
            
            private override init() {
                super.init()
            }
            
            override class func createShared() -> Self {
                return TestSingleton() as! Self
            }
        }
        
        // When
        let instance = TestSingleton.shared
        instance.state = "modified"
        
        // Then
        let instance2 = TestSingleton.shared
        XCTAssertEqual(instance2.state, "modified", "State should persist across accesses")
    }
    
    func testThreadSafeSingletonSubclass() {
        // Given
        class BaseSingleton: ThreadSafeSingleton {
            var baseValue: String = "base"
            
            private override init() {
                super.init()
            }
            
            override class func createShared() -> Self {
                return BaseSingleton() as! Self
            }
        }
        
        class DerivedSingleton: ThreadSafeSingleton {
            var derivedValue: String = "derived"
            
            private override init() {
                super.init()
            }
            
            override class func createShared() -> Self {
                return DerivedSingleton() as! Self
            }
        }
        
        // When
        let base = BaseSingleton.shared
        let derived = DerivedSingleton.shared
        
        // Then
        XCTAssertNotNil(base)
        XCTAssertNotNil(derived)
        XCTAssertTrue(type(of: base) == BaseSingleton.self)
        XCTAssertTrue(type(of: derived) == DerivedSingleton.self)
    }
    
    // MARK: - Singleton Protocol Tests
    
    func testSingletonProtocol() {
        // Given
        class ProtocolSingleton: ThreadSafeSingleton, Singleton {
            private override init() {
                super.init()
            }
            
            override class func createShared() -> Self {
                return ProtocolSingleton() as! Self
            }
        }
        
        // When
        let instance1 = ProtocolSingleton.shared
        let instance2 = ProtocolSingleton.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2, "Should conform to Singleton protocol")
    }
    
    // MARK: - ActorSingleton Protocol Tests
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func testActorSingletonProtocol() {
        // Given
        actor TestActorSingleton: ActorSingleton {
            static let shared = TestActorSingleton()
            
            private init() {}
            
            var value: String = "initial"
            
            func setValue(_ newValue: String) {
                value = newValue
            }
            
            func getValue() -> String {
                return value
            }
        }
        
        // When/Then
        let expectation = expectation(description: "Actor singleton test")
        
        Task {
            let instance1 = TestActorSingleton.shared
            let instance2 = TestActorSingleton.shared
            
            await instance1.setValue("modified")
            let value1 = await instance1.getValue()
            let value2 = await instance2.getValue()
            
            XCTAssertEqual(value1, "modified")
            XCTAssertEqual(value2, "modified", "Actor singleton should share state")
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
}

