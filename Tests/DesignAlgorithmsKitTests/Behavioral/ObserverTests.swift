//
//  ObserverTests.swift
//  DesignAlgorithmsKitTests
//
//  Unit tests for Observer Pattern
//

import XCTest
@testable import DesignAlgorithmsKit

final class ObserverTests: XCTestCase {
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
            
            init(id: String) {
                self.id = id
            }
            
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
}

