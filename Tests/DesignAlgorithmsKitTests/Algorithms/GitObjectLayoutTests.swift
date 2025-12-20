import XCTest
@testable import DesignAlgorithmsKit

final class GitObjectLayoutTests: XCTestCase {
    
    func testLayoutGeneration() {
        let hash = "a1b2c3d4e5f6"
        let layout = GitObjectLayout.layout(for: hash)
        
        XCTAssertEqual(layout.directory, "a1")
        XCTAssertEqual(layout.filename, "b2c3d4e5f6")
        XCTAssertEqual(layout.path, "a1/b2c3d4e5f6")
    }
    
    func testShortHash() {
        let hash = "ab"
        let layout = GitObjectLayout.layout(for: hash)
        
        // Expect behavior for short hashes (implementation specific: no split)
        XCTAssertEqual(layout.path, "ab")
        XCTAssertEqual(layout.directory, "")
        XCTAssertEqual(layout.filename, "ab")
        
        let hash2 = "a"
        let layout2 = GitObjectLayout.layout(for: hash2)
        XCTAssertEqual(layout2.path, "a")
        XCTAssertEqual(layout2.directory, "")
        XCTAssertEqual(layout2.filename, "a")
    }
    
    func testPathHelper() {
        let hash = "1234567890"
        XCTAssertEqual(GitObjectLayout.path(for: hash), "12/34567890")
    }
    
    func testStandardGitHash() {
        // Example SHA-1 hash
        let hash = "5e80dc522e0327ba4944d180bbf261904e545805"
        let layout = GitObjectLayout.layout(for: hash)
        
        XCTAssertEqual(layout.directory, "5e")
        XCTAssertEqual(layout.filename, "80dc522e0327ba4944d180bbf261904e545805")
        XCTAssertEqual(layout.path, "5e/80dc522e0327ba4944d180bbf261904e545805")
    }
}
