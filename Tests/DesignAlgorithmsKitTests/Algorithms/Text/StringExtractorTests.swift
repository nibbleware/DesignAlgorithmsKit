import XCTest
@testable import DesignAlgorithmsKit

final class StringExtractorTests: XCTestCase {
    func testRunsBetweenControlBytes() {
        var data = Data("ABC".utf8)
        data.append(0)
        data.append(contentsOf: Array("HELLO".utf8))
        data.append(0)
        data.append(contentsOf: Array(" WORLD ".utf8))
        data.append(1)
        XCTAssertEqual(StringExtractor.extractStrings(from: data), ["HELLO", "WORLD"])
    }

    func testLengthLimitsAndLatin1() {
        let long = Data(repeating: 0x41, count: 300)
        XCTAssertEqual(StringExtractor.extractStrings(from: long).first?.count, StringExtractor.maximumStringLength)
        XCTAssertEqual(StringExtractor.extractStrings(from: long, maxLength: 10), [String(repeating: "A", count: 10)])
        XCTAssertEqual(StringExtractor.extractStrings(from: Data([0x41, 0x42, 0x00]), minLength: 2), ["AB"])
        XCTAssertEqual(StringExtractor.extractStrings(from: Data([0xA9, 0x41, 0x42, 0x43])), ["\u{A9}ABC"])
        XCTAssertEqual(StringExtractor.extractStrings(from: Data()), [])
    }

    /// The implementation before the linear rewrite: a String built a Character at a time.
    private func reference(_ data: Data, minLength: Int, maxLength: Int) -> [String] {
        var strings: [String] = []
        var current = ""
        func flush() {
            let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count >= minLength { strings.append(trimmed) }
            current = ""
        }
        for byte in data {
            if (32...126).contains(byte) || byte >= 160 || byte == 9 || byte == 10 || byte == 13 {
                if current.count < maxLength { current.append(Character(UnicodeScalar(byte))) }
            } else {
                flush()
            }
        }
        flush()
        return strings
    }

    func testRunsAreTrimmedAndShortOnesDropped() {
        let data = Data("  HELLO WORLD \u{0}AB\u{0}\tCOPYRIGHT 1984\r\n".utf8)
        XCTAssertEqual(StringExtractor.extractStrings(from: data), ["HELLO WORLD", "COPYRIGHT 1984"])
    }

    func testLatin1BytesAreCharacters() {
        XCTAssertEqual(StringExtractor.extractStrings(from: Data([0xA9, 0x20, 0x31, 0x39, 0x38, 0x33])), ["\u{A9} 1983"])
    }

    func testLongRunsAreTruncated() {
        let data = Data(repeating: 0x41, count: 1000)
        XCTAssertEqual(StringExtractor.extractStrings(from: data, maxLength: 10), ["AAAAAAAAAA"])
    }

    /// The same strings as the reference on random bytes weighted toward text, whitespace and
    /// carriage return / line feed pairs, at several length limits.
    func testMatchesTheReferenceOnRandomData() {
        var generator = SystemRandomNumberGenerator()
        let extra: [UInt8] = [9, 10, 13, 13, 10, 0xA0, 0xA9, 0xE9, 0, 1, 0x80]
        let alphabet = Array(UInt8(32)...UInt8(126)) + extra
        for round in 0..<200 {
            let count = Int.random(in: 0...400, using: &generator)
            let data = Data((0..<count).map { _ in alphabet.randomElement(using: &generator)! })
            for (minLength, maxLength) in [(4, 256), (1, 8), (3, 3), (0, 1)] {
                XCTAssertEqual(StringExtractor.extractStrings(from: data, minLength: minLength, maxLength: maxLength),
                               reference(data, minLength: minLength, maxLength: maxLength),
                               "round \(round), min \(minLength), max \(maxLength)")
            }
        }
    }

    func testLargeDataIsFast() {
        var bytes = [UInt8](repeating: 0, count: 4_000_000)
        for index in bytes.indices where index % 97 != 0 { bytes[index] = UInt8(65 + index % 26) }
        let data = Data(bytes)
        let start = ContinuousClock.now
        XCTAssertEqual(StringExtractor.extractStrings(from: data).count, 41_238)
        XCTAssertLessThan(ContinuousClock.now - start, .seconds(5))
    }
}
