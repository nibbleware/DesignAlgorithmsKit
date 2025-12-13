import XCTest
@testable import DesignAlgorithmsKit

final class ChainOfResponsibilityTests: XCTestCase {
    
    // MARK: - Untyped Handler Tests
    
    class ConcreteHandlerA: BaseHandler {
        override func handle(_ request: Any) -> Any? {
            if let str = request as? String, str == "A" {
                return "Handled by A"
            }
            return super.handle(request)
        }
    }
    
    class ConcreteHandlerB: BaseHandler {
        override func handle(_ request: Any) -> Any? {
            if let str = request as? String, str == "B" {
                return "Handled by B"
            }
            return super.handle(request)
        }
    }
    
    func testUntypedChain() {
        let handlerA = ConcreteHandlerA()
        let handlerB = ConcreteHandlerB()
        
        handlerA.setNext(handlerB)
        
        XCTAssertEqual(handlerA.handle("A") as? String, "Handled by A")
        XCTAssertEqual(handlerA.handle("B") as? String, "Handled by B")
        XCTAssertNil(handlerA.handle("C"))
    }
    
    func testSingleHandlerChain() {
        let handler = ConcreteHandlerA()
        XCTAssertEqual(handler.handle("A") as? String, "Handled by A")
        XCTAssertNil(handler.handle("B"))
    }
    
    func testLongChain() {
        // Build a chain of 100 handlers
        // Only the last one handles "LAST"
        
        let first = BaseHandler()
        var current = first
        
        for _ in 0..<99 {
            let next = BaseHandler()
            current.setNext(next)
            current = next
        }
        
        class LastHandler: BaseHandler {
            override func handle(_ request: Any) -> Any? {
                if request as? String == "LAST" { return "DONE" }
                return super.handle(request)
            }
        }
        
        current.setNext(LastHandler())
        
        XCTAssertEqual(first.handle("LAST") as? String, "DONE")
        XCTAssertNil(first.handle("NOWHERE"))
    }
    
    // MARK: - Typed Handler Tests
    
    class TypedHandlerA: BaseTypedHandler<String, String> {
        override func handle(_ request: String) -> String? {
            if request == "A" {
                return "Handled by A"
            }
            return super.handle(request)
        }
    }
    
    class TypedHandlerB: BaseTypedHandler<String, String> {
        override func handle(_ request: String) -> String? {
            if request == "B" {
                return "Handled by B"
            }
            return super.handle(request)
        }
    }
    
    func testTypedChain() {
        let handlerA = TypedHandlerA()
        let handlerB = TypedHandlerB()
        
        handlerA.setNext(handlerB)
        
        XCTAssertEqual(handlerA.handle("A"), "Handled by A")
        XCTAssertEqual(handlerA.handle("B"), "Handled by B")
        XCTAssertNil(handlerA.handle("C"))
    }
    
    func testDynamicReconfiguration() {
        let h1 = TypedHandlerA()
        let h2 = TypedHandlerB()
        let h3 = TypedHandlerA() // Another A
        
        // Chain: A -> B
        h1.setNext(h2)
        XCTAssertEqual(h1.handle("B"), "Handled by B")
        
        // Chain: A -> A (h3) -> B
        h1.setNext(h3)
        h3.setNext(h2)
        
        // Should still work, just passes through h3 (which ignores "B") to h2
        XCTAssertEqual(h1.handle("B"), "Handled by B")
        
        // Remove h2: A -> A
        h3.nextHandler = nil
        XCTAssertNil(h1.handle("B"))
    }
}
