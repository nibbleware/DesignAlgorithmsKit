import XCTest
@testable import DesignAlgorithmsKit

/// Test strategy: maps every byte to "X" when the first byte is a marker, else declines.
private struct MarkerStrategy: TextDecodingStrategy {
    let name: String
    let marker: UInt8
    func decode(_ data: Data) -> String? {
        guard data.first == marker else { return nil }
        return String(repeating: name, count: 1)
    }
}

final class FallbackTextDecoderTests: XCTestCase {

    func testDefaultStrategyOrder() {
        XCTAssertEqual(FallbackTextDecoder.defaultStrategies.map(\.name),
                       ["us-ascii", "utf-8", "macintosh", "windows-1252"])
        XCTAssertTrue(FallbackTextDecoder.standard.stripsControlCharacters)
    }

    func testASCII() {
        let result = FallbackTextDecoder.standard.decodeWithStrategy(Data("HELLO\nWORLD\t!".utf8))
        XCTAssertEqual(result, DecodedText(text: "HELLO\nWORLD\t!", strategyName: "us-ascii"))
    }

    func testUTF8() {
        let result = FallbackTextDecoder.standard.decodeWithStrategy(Data("caf\u{E9} \u{2713}".utf8))
        XCTAssertEqual(result?.text, "caf\u{E9} \u{2713}")
        XCTAssertEqual(result?.strategyName, "utf-8")
    }

    func testMacRomanFallbackForInvalidUTF8() {
        // 0x8E is "é" in Mac OS Roman and invalid as a lone UTF-8 byte.
        let result = FallbackTextDecoder.standard.decodeWithStrategy(Data([0x63, 0x61, 0x66, 0x8E]))
        XCTAssertEqual(result?.text, "caf\u{E9}")
        XCTAssertEqual(result?.strategyName, "macintosh")
    }

    func testControlCharactersStrippedKeepingNewlinesAndTabs() {
        let data = Data([0x41, 0x00, 0x07, 0x42, 0x0D, 0x0A, 0x09, 0x43, 0x1B])
        XCTAssertEqual(data.decodedText(), "AB\r\n\tC")
    }

    func testStrippingCanBeDisabled() {
        let decoder = FallbackTextDecoder(stripsControlCharacters: false)
        XCTAssertEqual(decoder.decode(Data([0x41, 0x00, 0x42])), "A\u{0}B")
    }

    func testOnlyControlCharactersOrEmptyIsNil() {
        XCTAssertNil(Data().decodedText())
        XCTAssertNil(Data([0x00, 0x01, 0x02]).decodedText())
    }

    func testRemovingControlCharacters() {
        XCTAssertEqual(FallbackTextDecoder.removingControlCharacters(from: "a\u{0}b\u{FEFF}c\nd"), "abc\nd")
    }

    func testCustomStrategiesBeforeAndAfterDefaults() {
        let before = MarkerStrategy(name: "first", marker: 0x01)
        let after = MarkerStrategy(name: "last", marker: 0x02)
        let decoder = FallbackTextDecoder(before: [before], after: [after])
        XCTAssertEqual(decoder.strategies.map(\.name),
                       ["first", "us-ascii", "utf-8", "macintosh", "windows-1252", "last"])
        XCTAssertEqual(decoder.decodeWithStrategy(Data([0x01, 0x41]))?.strategyName, "first")
        // Declined by "first", decoded by a default
        XCTAssertEqual(decoder.decodeWithStrategy(Data([0x41]))?.strategyName, "us-ascii")
    }

    func testExplicitStrategyList() {
        let decoder = FallbackTextDecoder(strategies: [StringEncodingStrategy.utf8])
        XCTAssertNil(decoder.decode(Data([0xFF, 0xFE, 0x8E])))
        XCTAssertEqual(StringEncodingStrategy(.isoLatin1).name, "iso-8859-1")
    }

    func testRegistryOrderingAndReplacement() {
        let registry = TextDecoderRegistry()
        registry.register(MarkerStrategy(name: "b", marker: 0x01))
        registry.register(MarkerStrategy(name: "a", marker: 0x01))
        registry.register(MarkerStrategy(name: "high", marker: 0x01), priority: 10)
        registry.register(MarkerStrategy(name: "tail", marker: 0x02), placement: .afterDefaults)

        XCTAssertEqual(registry.strategies(placement: .beforeDefaults).map(\.name), ["high", "a", "b"])
        XCTAssertEqual(registry.makeDecoder().strategies.map(\.name),
                       ["high", "a", "b", "us-ascii", "utf-8", "macintosh", "windows-1252", "tail"])
        XCTAssertEqual(registry.decode(Data([0x01])), "high")

        registry.register(MarkerStrategy(name: "high", marker: 0x03), priority: -1)
        XCTAssertEqual(registry.strategies(placement: .beforeDefaults).map(\.name), ["a", "b", "high"])

        registry.unregister("a")
        registry.unregister("b")
        registry.unregister("high")
        XCTAssertEqual(registry.decode(Data([0x01])), nil)
        XCTAssertEqual(registry.decode(Data("ok".utf8)), "ok")
    }
}
