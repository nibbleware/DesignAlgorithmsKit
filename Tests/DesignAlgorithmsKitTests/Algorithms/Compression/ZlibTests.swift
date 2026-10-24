import XCTest
@testable import DesignAlgorithmsKit

final class ZlibTests: XCTestCase {

    private let sample = Data((String(repeating: "The quick brown fox jumps over the lazy dog. ", count: 200)).utf8)

    func testRoundTripAllFramings() throws {
        for framing in Zlib.Framing.allCases {
            let compressed = try Zlib.compress(data: sample, framing: framing)
            XCTAssertLessThan(compressed.count, sample.count, "\(framing)")
            XCTAssertEqual(try Zlib.decompress(data: compressed, framing: framing), sample, "\(framing)")
        }
    }

    func testFramingWindowBits() {
        XCTAssertEqual(Zlib.Framing.zlib.windowBits, 15)
        XCTAssertEqual(Zlib.Framing.gzip.windowBits, 31)
        XCTAssertEqual(Zlib.Framing.rawDeflate.windowBits, -15)
    }

    func testGzipFramingHeaderAndDefaultWindowBits() throws {
        let compressed = try Zlib.compress(data: sample, windowBits: 31)
        XCTAssertEqual(compressed[0], 0x1F)
        XCTAssertEqual(compressed[1], 0x8B)
        // Default window bits are gzip
        XCTAssertEqual(try Zlib.decompress(data: compressed), sample)
        XCTAssertEqual(try Zlib.decompress(data: Zlib.compress(data: sample)), sample)
    }

    func testZlibFramingHeader() throws {
        let compressed = try Zlib.compress(data: sample, framing: .zlib)
        XCTAssertEqual(compressed[0], 0x78)
        XCTAssertEqual((UInt16(compressed[0]) << 8 | UInt16(compressed[1])) % 31, 0)
    }

    func testAutoDetectZlibOrGzip() throws {
        XCTAssertEqual(try Zlib.decompress(data: Zlib.compress(data: sample, framing: .zlib), windowBits: 47), sample)
        XCTAssertEqual(try Zlib.decompress(data: Zlib.compress(data: sample, framing: .gzip), windowBits: 47), sample)
    }

    func testRawDeflateInteropWithGzip() throws {
        let gz = try Gzip.compress(data: sample)
        let payload = gz.subdata(in: 10..<(gz.count - 8))
        XCTAssertEqual(try Zlib.decompress(data: payload, windowBits: -15), sample)
    }

    func testGzipReadsZlibGzipFraming() throws {
        let gz = try Zlib.compress(data: sample, framing: .gzip)
        XCTAssertEqual(try Gzip.decompress(data: gz), sample)
    }

    func testCompressionLevels() throws {
        let stored = try Zlib.compress(data: sample, windowBits: -15, level: 0)
        let best = try Zlib.compress(data: sample, windowBits: -15, level: 9)
        XCTAssertGreaterThan(stored.count, best.count)
        XCTAssertEqual(try Zlib.decompress(data: stored, windowBits: -15), sample)
        XCTAssertEqual(try Zlib.decompress(data: best, windowBits: -15), sample)
    }

    func testEmptyInput() throws {
        XCTAssertEqual(try Zlib.decompress(data: Data(), framing: .rawDeflate), Data())
        for framing in Zlib.Framing.allCases {
            let compressed = try Zlib.compress(data: Data(), framing: framing)
            XCTAssertFalse(compressed.isEmpty)
            XCTAssertEqual(try Zlib.decompress(data: compressed, framing: framing), Data())
        }
    }

    func testLargeIncompressibleInputSpansBuffers() throws {
        var generator = SystemRandomNumberGenerator()
        let random = Data((0..<300_000).map { _ in UInt8.random(in: 0...255, using: &generator) })
        let compressed = try Zlib.compress(data: random, framing: .rawDeflate)
        XCTAssertEqual(try Zlib.decompress(data: compressed, framing: .rawDeflate), random)
    }

    func testTruncatedStreamThrows() throws {
        let compressed = try Zlib.compress(data: sample, framing: .gzip)
        let truncated = compressed.prefix(compressed.count / 2)
        XCTAssertThrowsError(try Zlib.decompress(data: Data(truncated), framing: .gzip)) { error in
            XCTAssertTrue(error is ZlibError)
        }
    }

    func testCorruptStreamThrows() {
        XCTAssertThrowsError(try Zlib.decompress(data: Data("Not compressed data at all".utf8), framing: .zlib)) { error in
            XCTAssertTrue(error is ZlibError)
        }
    }

    func testInvalidWindowBitsThrows() {
        XCTAssertThrowsError(try Zlib.compress(data: sample, windowBits: 99)) { error in
            XCTAssertEqual(error as? ZlibError, .initializationFailed)
        }
        XCTAssertThrowsError(try Zlib.decompress(data: sample, windowBits: 99)) { error in
            XCTAssertEqual(error as? ZlibError, .initializationFailed)
        }
    }

    func testTrailingBytesAfterStreamAreIgnored() throws {
        var compressed = try Zlib.compress(data: sample, framing: .rawDeflate)
        compressed.append(contentsOf: [0xDE, 0xAD, 0xBE, 0xEF])
        XCTAssertEqual(try Zlib.decompress(data: compressed, framing: .rawDeflate), sample)
    }
}
