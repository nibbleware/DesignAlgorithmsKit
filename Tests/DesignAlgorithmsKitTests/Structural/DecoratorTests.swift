import XCTest
@testable import DesignAlgorithmsKit

final class DecoratorTests: XCTestCase {
    
    // Component Interface
    protocol TextComponent: AnyObject {
        func render() -> String
    }
    
    // Concrete Component
    class SimpleText: TextComponent {
        func render() -> String {
            return "Text"
        }
    }
    
    // Decorator
    class BoldDecorator: BaseDecorator<TextComponent>, TextComponent {
        func render() -> String {
            return "<b>" + component.render() + "</b>"
        }
    }
    
    class ItalicDecorator: BaseDecorator<TextComponent>, TextComponent {
        func render() -> String {
            return "<i>" + component.render() + "</i>"
        }
    }
    
    class UppercaseDecorator: BaseDecorator<TextComponent>, TextComponent {
        func render() -> String {
            return component.render().uppercased()
        }
    }
    
    func testDecoratorChain() {
        let simple = SimpleText()
        XCTAssertEqual(simple.render(), "Text")
        
        let bold = BoldDecorator(simple)
        XCTAssertEqual(bold.render(), "<b>Text</b>")
        
        // Italic(Bold(Text))
        let boldItalic = ItalicDecorator(bold)
        XCTAssertEqual(boldItalic.render(), "<i><b>Text</b></i>")
    }
    
    func testOrderOfDecorators() {
        let simple = SimpleText()
        
        // Upper(Bold(Text)) -> <B>TEXT</B>
        let upperBold = UppercaseDecorator(BoldDecorator(simple))
        XCTAssertEqual(upperBold.render(), "<B>TEXT</B>")
        
        // Bold(Upper(Text)) -> <b>TEXT</b>
        let boldUpper = BoldDecorator(UppercaseDecorator(simple))
        XCTAssertEqual(boldUpper.render(), "<b>TEXT</b>")
    }
    
    func testMultipleLayers() {
        // Deep stacking
        var component: TextComponent = SimpleText()
        
        // Wrap 10 times in Bold
        for _ in 0..<10 {
            component = BoldDecorator(component)
        }
        
        let result = component.render()
        let openingTags = String(repeating: "<b>", count: 10)
        let closingTags = String(repeating: "</b>", count: 10)
        
        XCTAssertEqual(result, "\(openingTags)Text\(closingTags)")
    }
    
    func testBaseDecoratorProperties() {
        let simple = SimpleText()
        let decorator = BaseDecorator(simple)
        
        // Check access to underlying component
        XCTAssertTrue(decorator.component === simple)
    }
}
