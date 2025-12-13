import XCTest
@testable import DesignAlgorithmsKit

final class IteratorTests: XCTestCase {
    
    // MARK: - Array Iterator
    
    func testArrayIterator() {
        let items = [1, 2, 3]
        let iterator = ArrayIterator(items)
        
        XCTAssertTrue(iterator.hasNext())
        XCTAssertEqual(iterator.next(), 1)
        
        XCTAssertTrue(iterator.hasNext())
        XCTAssertEqual(iterator.next(), 2)
        
        XCTAssertTrue(iterator.hasNext())
        XCTAssertEqual(iterator.next(), 3)
        
        XCTAssertFalse(iterator.hasNext())
        XCTAssertNil(iterator.next())
    }
    
    func testEmptyArrayIterator() {
        let items: [Int] = []
        let iterator = ArrayIterator(items)
        
        XCTAssertFalse(iterator.hasNext())
        XCTAssertNil(iterator.next())
    }
    
    func testSingleElementArrayIterator() {
        let items = [1]
        let iterator = ArrayIterator(items)
        
        XCTAssertTrue(iterator.hasNext())
        XCTAssertEqual(iterator.next(), 1)
        XCTAssertFalse(iterator.hasNext())
    }
    
    // MARK: - Tree Iterator
    
    struct Node {
        let value: Int
        let children: [Node]
    }
    
    func testTreeIterator() {
        // Tree structure:
        //      1
        //    /   \
        //   2     3
        //  / \
        // 4   5
        
        let node4 = Node(value: 4, children: [])
        let node5 = Node(value: 5, children: [])
        let node2 = Node(value: 2, children: [node4, node5])
        let node3 = Node(value: 3, children: [])
        let root = Node(value: 1, children: [node2, node3])
        
        // Depth-first traversal expected: 1, 2, 4, 5, 3
        let iterator = TreeIterator(root: root) { node in
            return node.children
        }
        
        var result: [Int] = []
        while let node = iterator.next() {
            result.append(node.value)
        }
        
        XCTAssertEqual(result, [1, 2, 4, 5, 3])
    }
    
    func testSingleNodeTreeIterator() {
        let root = Node(value: 1, children: [])
        let iterator = TreeIterator(root: root) { $0.children }
        
        XCTAssertTrue(iterator.hasNext())
        let val = iterator.next()
        XCTAssertEqual(val?.value, 1)
        XCTAssertFalse(iterator.hasNext())
    }
    
    func testDeepTreePath() {
        // 1 -> 2 -> 3
        let node3 = Node(value: 3, children: [])
        let node2 = Node(value: 2, children: [node3])
        let node1 = Node(value: 1, children: [node2])
        
        let iterator = TreeIterator(root: node1) { $0.children }
        
        XCTAssertEqual(iterator.next()?.value, 1)
        XCTAssertEqual(iterator.next()?.value, 2)
        XCTAssertEqual(iterator.next()?.value, 3)
        XCTAssertNil(iterator.next())
    }
}
