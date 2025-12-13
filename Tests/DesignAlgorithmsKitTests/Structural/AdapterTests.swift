import XCTest
@testable import DesignAlgorithmsKit

final class AdapterTests: XCTestCase {
    
    // MARK: - BaseAdapter Tests
    
    func testBaseAdapterInitialization() {
        let adapterID = "testAdapter"
        let adapter = BaseAdapter(adapterID: adapterID)
        XCTAssertEqual(adapter.adapterID, adapterID)
    }
    
    func testBaseAdapterCanHandleDefault() {
        let adapter = BaseAdapter(adapterID: "test")
        XCTAssertFalse(adapter.canHandle("test"), "Base adapter should return false by default")
        XCTAssertFalse(adapter.canHandle(42), "Base adapter should return false by default")
    }
    
    // MARK: - Adapter Pattern Implementation Tests
    
    func testAdapterPattern() {
        protocol Target { func request() -> String }
        class Adaptee { func specificRequest() -> String { return "Adaptee" } }
        
        class AdapteeAdapter: BaseAdapter, Target {
            private let adaptee: Adaptee
            init(adaptee: Adaptee) {
                self.adaptee = adaptee
                super.init(adapterID: "adapteeAdapter")
            }
            func request() -> String { return adaptee.specificRequest() }
            override func canHandle(_ input: Any) -> Bool { return input is Adaptee }
        }
        
        let adaptee = Adaptee()
        let adapter = AdapteeAdapter(adaptee: adaptee)
        let target: Target = adapter
        
        XCTAssertEqual(target.request(), "Adaptee")
        XCTAssertTrue(adapter.canHandle(adaptee))
        XCTAssertFalse(adapter.canHandle("not an Adaptee"))
    }
    
    func testAdapterWithDifferentTypes() {
        protocol StringTarget { func getString() -> String }
        class IntAdaptee {
            let value: Int
            init(value: Int) { self.value = value }
        }
        
        class IntToStringAdapter: BaseAdapter, StringTarget {
            private let adaptee: IntAdaptee
            init(adaptee: IntAdaptee) {
                self.adaptee = adaptee
                super.init(adapterID: "intToStringAdapter")
            }
            func getString() -> String { return String(adaptee.value) }
            override func canHandle(_ input: Any) -> Bool { return input is IntAdaptee }
        }
        
        let adaptee = IntAdaptee(value: 42)
        let adapter = IntToStringAdapter(adaptee: adaptee)
        let target: StringTarget = adapter
        
        XCTAssertEqual(target.getString(), "42")
        XCTAssertTrue(adapter.canHandle(adaptee))
    }
    
    // MARK: - Inheritance Handling
    
    func testAdapterInheritanceHandling() {
        // Given
        class Parent {}
        class Child: Parent {}
        
        class ParentAdapter: BaseAdapter {
            override func canHandle(_ input: Any) -> Bool {
                return input is Parent
            }
        }
        
        let adapter = ParentAdapter(adapterID: "parent")
        
        // Then - Should handle both parent and child
        XCTAssertTrue(adapter.canHandle(Parent()))
        XCTAssertTrue(adapter.canHandle(Child()))
        XCTAssertFalse(adapter.canHandle("String"))
    }
    
    func testMultipleAdapters() {
        protocol Target { func process() -> String }
        class Adaptee1 { func m1() -> String { return "1" } }
        class Adaptee2 { func m2() -> String { return "2" } }
        
        class Adapter1: BaseAdapter, Target {
            let a: Adaptee1
            init(a: Adaptee1) { self.a = a; super.init(adapterID: "1") }
            func process() -> String { a.m1() }
            override func canHandle(_ input: Any) -> Bool { input is Adaptee1 }
        }
        
        class Adapter2: BaseAdapter, Target {
            let a: Adaptee2
            init(a: Adaptee2) { self.a = a; super.init(adapterID: "2") }
            func process() -> String { a.m2() }
            override func canHandle(_ input: Any) -> Bool { input is Adaptee2 }
        }
        
        let a1 = Adaptee1()
        let a2 = Adaptee2()
        let ad1 = Adapter1(a: a1)
        let ad2 = Adapter2(a: a2)
        
        XCTAssertEqual(ad1.process(), "1")
        XCTAssertEqual(ad2.process(), "2")
        XCTAssertTrue(ad1.canHandle(a1))
        XCTAssertFalse(ad1.canHandle(a2))
    }
    
    func testAdapterProtocolConformance() {
        class TestAdapter: BaseAdapter {}
        let adapter: Adapter = TestAdapter(adapterID: "test")
        XCTAssertEqual(adapter.adapterID, "test")
    }
}
