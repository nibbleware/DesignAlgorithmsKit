import XCTest
@testable import DesignAlgorithmsKit

final class ObserverTests: XCTestCase {
    
    // MARK: - Basic Functionality
    
    func testObserverPattern() {
        // Given
        class TestObservable: BaseObservable {}
        class TestObserver: Observer {
            var receivedEvents: [Any] = []
            
            func didReceiveNotification(from observable: any Observable, event: Any) {
                receivedEvents.append(event)
            }
        }
        
        let observable = TestObservable()
        let observer = TestObserver()
        
        // When
        observable.addObserver(observer)
        observable.notifyObservers(event: "event1")
        observable.notifyObservers(event: "event2")
        
        // Then
        XCTAssertEqual(observer.receivedEvents.count, 2)
        XCTAssertEqual(observer.receivedEvents[0] as? String, "event1")
        XCTAssertEqual(observer.receivedEvents[1] as? String, "event2")
    }
    
    func testRemoveObserver() {
        // Given
        class TestObservable: BaseObservable {}
        class TestObserver: Observer {
            var receivedEvents: [Any] = []
            
            func didReceiveNotification(from observable: any Observable, event: Any) {
                receivedEvents.append(event)
            }
        }
        
        let observable = TestObservable()
        let observer = TestObserver()
        
        // When
        observable.addObserver(observer)
        observable.notifyObservers(event: "event1")
        observable.removeObserver(observer)
        observable.notifyObservers(event: "event2")
        
        // Then
        XCTAssertEqual(observer.receivedEvents.count, 1)
        XCTAssertEqual(observer.receivedEvents[0] as? String, "event1")
    }
    
    func testMultipleObservers() {
        // Given
        class TestObservable: BaseObservable {}
        class TestObserver: Observer {
            let id: String
            var receivedEvents: [Any] = []
            
            init(id: String) { self.id = id }
            
            func didReceiveNotification(from observable: any Observable, event: Any) {
                receivedEvents.append(event)
            }
        }
        
        let observable = TestObservable()
        let observer1 = TestObserver(id: "1")
        let observer2 = TestObserver(id: "2")
        
        // When
        observable.addObserver(observer1)
        observable.addObserver(observer2)
        observable.notifyObservers(event: "event")
        
        // Then
        XCTAssertEqual(observer1.receivedEvents.count, 1)
        XCTAssertEqual(observer2.receivedEvents.count, 1)
    }
    
    // MARK: - Weak Reference Tests
    
    func testWeakReference() {
        class TestObservable: BaseObservable {}
        class TestObserver: Observer {
            func didReceiveNotification(from observable: any Observable, event: Any) {}
        }
        
        let observable = TestObservable()
        
        // Create an observer in a local scope so it gets deallocated
        var observer: TestObserver? = TestObserver()
        weak var weakObserver = observer
        
        observable.addObserver(observer!)
        XCTAssertNotNil(weakObserver)
        
        // Remove strong reference
        observer = nil
        
        // Verify deallocation
        XCTAssertNil(weakObserver, "Observer should have been deallocated")
        
        // Verify notification doesn't crash
        observable.notifyObservers(event: "test")
        
        // Verify cleanup on next add
        // The implementation cleans up on addObserver
        observable.addObserver(TestObserver())
        // Cannot easily inspect internal array count without reflection or subclassing exposing it,
        // but 'addObserver' is the trigger for cleanup in BaseObservable.
    }
    
    // MARK: - Reentrancy and Concurrency
    
    func testReentrancySafe() {
        // Test removing self during notification
        class TestObservable: BaseObservable {}
        class TestObserver: Observer {
            var observable: TestObservable?
            var receivedCount = 0
            
            func didReceiveNotification(from observable: any Observable, event: Any) {
                receivedCount += 1
                if let obs = self.observable {
                    obs.removeObserver(self)
                }
            }
        }
        
        let observable = TestObservable()
        let observer = TestObserver()
        observer.observable = observable
        
        observable.addObserver(observer)
        
        // First notification triggers removal
        observable.notifyObservers(event: "1")
        XCTAssertEqual(observer.receivedCount, 1)
        
        // Second notification should not reach observer
        observable.notifyObservers(event: "2")
        XCTAssertEqual(observer.receivedCount, 1)
    }
    
    func testConcurrentAccess() {
        class TestObservable: BaseObservable {}
        class TestObserver: Observer {
            func didReceiveNotification(from observable: any Observable, event: Any) {
                // Do work
            }
        }
        
        let observable = TestObservable()
        let iterations = 1000
        let expectation = self.expectation(description: "Concurrent observer access")
        expectation.expectedFulfillmentCount = iterations
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let observer = TestObserver()
            observable.addObserver(observer)
            
            if i % 2 == 0 {
                observable.notifyObservers(event: i)
            }
            
            if i % 3 == 0 {
                observable.removeObserver(observer)
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testDuplicateAddition() {
        class TestObservable: BaseObservable {}
        class TestObserver: Observer {
            var count = 0
            func didReceiveNotification(from observable: any Observable, event: Any) {
                count += 1
            }
        }
        
        let observable = TestObservable()
        let observer = TestObserver()
        
        // Add twice
        observable.addObserver(observer)
        observable.addObserver(observer)
        
        observable.notifyObservers(event: "test")
        
        // Should only be notified once
        XCTAssertEqual(observer.count, 1)
    }
}
