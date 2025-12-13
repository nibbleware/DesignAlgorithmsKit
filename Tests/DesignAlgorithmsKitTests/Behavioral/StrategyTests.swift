import XCTest
@testable import DesignAlgorithmsKit

final class StrategyTests: XCTestCase {
    
    // MARK: - Basic Implementation
    
    func testStrategyPattern() {
        // Given
        struct AdditionStrategy: Strategy {
            let strategyID = "addition"
            func execute(_ a: Int, _ b: Int) -> Int { return a + b }
        }
        
        struct MultiplicationStrategy: Strategy {
            let strategyID = "multiplication"
            func execute(_ a: Int, _ b: Int) -> Int { return a * b }
        }
        
        // When
        let context1 = StrategyContext(strategy: AdditionStrategy())
        let result1 = context1.getStrategy().execute(5, 3)
        
        let context2 = StrategyContext(strategy: MultiplicationStrategy())
        let result2 = context2.getStrategy().execute(5, 3)
        
        // Then
        XCTAssertEqual(result1, 8)
        XCTAssertEqual(result2, 15)
    }
    
    func testContextSwitching() {
        // Given
        struct TestStrategy: Strategy {
            let strategyID: String
            let val: Int
        }
        
        let s1 = TestStrategy(strategyID: "s1", val: 1)
        let s2 = TestStrategy(strategyID: "s2", val: 2)
        
        let context = StrategyContext(strategy: s1)
        XCTAssertEqual(context.getStrategy().val, 1)
        
        context.setStrategy(s2)
        XCTAssertEqual(context.getStrategy().val, 2)
        
        context.setStrategy(s1)
        XCTAssertEqual(context.getStrategy().val, 1)
    }
    
    // MARK: - Inheritance and Types
    
    func testBaseStrategy() {
        let baseStrategy = BaseStrategy(strategyID: "base-test")
        XCTAssertEqual(baseStrategy.strategyID, "base-test")
    }
    
    func testBaseStrategyInheritance() {
        class CustomStrategy: BaseStrategy {
            init() { super.init(strategyID: "custom") }
            func op() -> String { return "op" }
        }
        
        let strategy = CustomStrategy()
        XCTAssertEqual(strategy.strategyID, "custom")
        XCTAssertEqual(strategy.op(), "op")
    }
    
    // MARK: - Polymorphism
    
    protocol MathStrategy: Strategy {
        func calculate(_ a: Int, _ b: Int) -> Int
    }
    
    struct Add: MathStrategy {
        var strategyID = "add"
        func calculate(_ a: Int, _ b: Int) -> Int { a + b }
    }
    
    struct Subtract: MathStrategy {
        var strategyID = "subtract"
        func calculate(_ a: Int, _ b: Int) -> Int { a - b }
    }
    
    func testPolymorphicContext() {
        let context = StrategyContext<BoxedMathStrategy>(strategy: BoxedMathStrategy(Add()))
        
        XCTAssertEqual(context.getStrategy().calculate(10, 5), 15)
        
        context.setStrategy(BoxedMathStrategy(Subtract()))
        XCTAssertEqual(context.getStrategy().calculate(10, 5), 5)
    }
    
    // Type erasure wrapper for the test because StrategyContext is generic over a specific concrete type
    // or a protocol if used as an existentials (but StrategyContext<P> requires P: Strategy).
    // Protocols conforming to protocols don't satisfy P: Strategy for generic constraints in Swift 
    // without `any` or box, testing here verifies the usage pattern.
    struct BoxedMathStrategy: MathStrategy {
        let strategyID: String
        private let _calculate: (Int, Int) -> Int
        
        init<S: MathStrategy>(_ strategy: S) {
            self.strategyID = strategy.strategyID
            self._calculate = strategy.calculate
        }
        
        func calculate(_ a: Int, _ b: Int) -> Int {
            _calculate(a, b)
        }
    }
}
