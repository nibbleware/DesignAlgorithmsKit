import XCTest
@testable import DesignAlgorithmsKit

final class FilenameTokenizerTests: XCTestCase {
    
    func testTokenization() {
        let cases: [(String, [String])] = [
            ("simple_file_name", ["simple", "file", "name"]),
            ("camelCaseFile", ["camel", "Case", "File"]),
            ("PascalCaseFile", ["Pascal", "Case", "File"]),
            ("kebab-case-file", ["kebab", "case", "file"]),
            ("PDFExtractor", ["PDF", "Extractor"]),
            ("PDFExtractor.swift", ["PDF", "Extractor", "swift"]),
            ("file123", ["file", "123"]),
            ("123file", ["123", "file"]),
            ("complex_FileName-123.txt", ["complex", "File", "Name", "123", "txt"]),
            ("URLSession", ["URL", "Session"]),
            ("HTTPClient", ["HTTP", "Client"]),
             // Verify number splitting
            ("v2", ["v", "2"])
        ]
        
        for (input, expected) in cases {
            let result = FilenameTokenizer.tokenize(input)
            XCTAssertEqual(result, expected, "Failed for input: \(input)")
        }
    }
}
