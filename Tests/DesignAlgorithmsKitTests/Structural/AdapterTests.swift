//
//  AdapterTests.swift
//  DesignAlgorithmsKitTests
//
//  Unit tests for Adapter Pattern
//

import XCTest
@testable import DesignAlgorithmsKit

final class AdapterTests: XCTestCase {
    
    // MARK: - BaseAdapter Tests
    
    func testBaseAdapterInitialization() {
        // Given
        let adapterID = "testAdapter"
        
        // When
        let adapter = BaseAdapter(adapterID: adapterID)
        
        // Then
        XCTAssertEqual(adapter.adapterID, adapterID)
    }
    
    func testBaseAdapterCanHandleDefault() {
        // Given
        let adapter = BaseAdapter(adapterID: "test")
        
        // When/Then
        XCTAssertFalse(adapter.canHandle("test"), "Base adapter should return false by default")
        XCTAssertFalse(adapter.canHandle(42), "Base adapter should return false by default")
    }
    
    // MARK: - Adapter Pattern Implementation Tests
    
    func testAdapterPattern() {
        // Given
        protocol Target {
            func request() -> String
        }
        
        class Adaptee {
            func specificRequest() -> String {
                return "Adaptee"
            }
        }
        
        class AdapteeAdapter: BaseAdapter, Target {
            private let adaptee: Adaptee
            
            init(adaptee: Adaptee) {
                self.adaptee = adaptee
                super.init(adapterID: "adapteeAdapter")
            }
            
            func request() -> String {
                return adaptee.specificRequest()
            }
            
            override func canHandle(_ input: Any) -> Bool {
                return input is Adaptee
            }
        }
        
        // When
        let adaptee = Adaptee()
        let adapter = AdapteeAdapter(adaptee: adaptee)
        let target: Target = adapter
        
        // Then
        XCTAssertEqual(target.request(), "Adaptee")
        XCTAssertTrue(adapter.canHandle(adaptee))
        XCTAssertFalse(adapter.canHandle("not an Adaptee"))
    }
    
    func testAdapterWithDifferentTypes() {
        // Given
        protocol StringTarget {
            func getString() -> String
        }
        
        class IntAdaptee {
            let value: Int
            
            init(value: Int) {
                self.value = value
            }
        }
        
        class IntToStringAdapter: BaseAdapter, StringTarget {
            private let adaptee: IntAdaptee
            
            init(adaptee: IntAdaptee) {
                self.adaptee = adaptee
                super.init(adapterID: "intToStringAdapter")
            }
            
            func getString() -> String {
                return String(adaptee.value)
            }
            
            override func canHandle(_ input: Any) -> Bool {
                return input is IntAdaptee
            }
        }
        
        // When
        let adaptee = IntAdaptee(value: 42)
        let adapter = IntToStringAdapter(adaptee: adaptee)
        let target: StringTarget = adapter
        
        // Then
        XCTAssertEqual(target.getString(), "42")
        XCTAssertTrue(adapter.canHandle(adaptee))
    }
    
    func testMultipleAdapters() {
        // Given
        protocol Target {
            func process() -> String
        }
        
        class Adaptee1 {
            func method1() -> String { return "Adaptee1" }
        }
        
        class Adaptee2 {
            func method2() -> String { return "Adaptee2" }
        }
        
        class Adapter1: BaseAdapter, Target {
            private let adaptee: Adaptee1
            
            init(adaptee: Adaptee1) {
                self.adaptee = adaptee
                super.init(adapterID: "adapter1")
            }
            
            func process() -> String {
                return adaptee.method1()
            }
            
            override func canHandle(_ input: Any) -> Bool {
                return input is Adaptee1
            }
        }
        
        class Adapter2: BaseAdapter, Target {
            private let adaptee: Adaptee2
            
            init(adaptee: Adaptee2) {
                self.adaptee = adaptee
                super.init(adapterID: "adapter2")
            }
            
            func process() -> String {
                return adaptee.method2()
            }
            
            override func canHandle(_ input: Any) -> Bool {
                return input is Adaptee2
            }
        }
        
        // When
        let adaptee1 = Adaptee1()
        let adaptee2 = Adaptee2()
        let adapter1 = Adapter1(adaptee: adaptee1)
        let adapter2 = Adapter2(adaptee: adaptee2)
        
        // Then
        XCTAssertEqual(adapter1.process(), "Adaptee1")
        XCTAssertEqual(adapter2.process(), "Adaptee2")
        XCTAssertTrue(adapter1.canHandle(adaptee1))
        XCTAssertTrue(adapter2.canHandle(adaptee2))
        XCTAssertFalse(adapter1.canHandle(adaptee2))
        XCTAssertFalse(adapter2.canHandle(adaptee1))
    }
    
    func testAdapterProtocolConformance() {
        // Given
        class TestAdapter: BaseAdapter {
            override init(adapterID: String) {
                super.init(adapterID: adapterID)
            }
        }
        
        // When
        let adapter: Adapter = TestAdapter(adapterID: "test")
        
        // Then
        XCTAssertEqual(adapter.adapterID, "test")
        XCTAssertFalse(adapter.canHandle("test"))
    }
}

