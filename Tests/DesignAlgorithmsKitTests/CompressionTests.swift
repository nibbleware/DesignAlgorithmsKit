import XCTest
@testable import DesignAlgorithmsKit

final class CompressionTests: XCTestCase {
    
    func testRoundTrip() throws {
        let originalText = "Hello, GZIP World! " + String(repeating: "Repeating content ", count: 100)
        let originalData = originalText.data(using: .utf8)!
        
        let compressed = try Gzip.compress(data: originalData)
        XCTAssertTrue(compressed.count < originalData.count, "Compressed data should be smaller for redundant text")
        
        // Verify GZIP header magic numbers (0x1f 0x8b)
        XCTAssertEqual(compressed[0], 0x1f)
        XCTAssertEqual(compressed[1], 0x8b)
        
        let decompressed = try Gzip.decompress(data: compressed)
        let decompressedText = String(data: decompressed, encoding: .utf8)
        
        XCTAssertEqual(originalText, decompressedText)
    }
    
    func testDecompressInvalidData() {
        let badData = "Not GZIP Data".data(using: .utf8)!
        XCTAssertThrowsError(try Gzip.decompress(data: badData)) { error in
            guard let gzipError = error as? Gzip.Error else {
                XCTFail("Wrong error type")
                return
            }
            XCTAssertTrue(gzipError == .invalidData || gzipError == .decompressionFailed)
        }
    }
    
    func testDecompressEmptyData() throws {
        let empty = Data()
        // Empty data lacks GZIP header, so it should throw invalidData
        XCTAssertThrowsError(try Gzip.decompress(data: empty)) { error in
            XCTAssertEqual(error as? Gzip.Error, .invalidData)
        }
    }
    
    func testCompressEmptyData() throws {
        // Compressing empty data should still produce a valid GZIP header + footer
        let emptyInfo = Data()
        let compressed = try Gzip.compress(data: emptyInfo)
        XCTAssertTrue(compressed.count > 0) 
        
        let decompressed = try Gzip.decompress(data: compressed)
        XCTAssertTrue(decompressed.isEmpty)
    }

    // MARK: - Trailer verification (fix-algorithm-edge-cases)

    private func sample() throws -> Data {
        try Gzip.compress(data: Data(String(repeating: "trailer check ", count: 20).utf8))
    }

    func testCorruptedCRCThrows() throws {
        var data = try sample()
        data[data.count - 8] ^= 0xFF
        XCTAssertThrowsError(try Gzip.decompress(data: data)) { error in
            XCTAssertEqual(error as? Gzip.Error, .invalidData)
        }
    }

    func testCorruptedISizeThrows() throws {
        var data = try sample()
        data[data.count - 1] ^= 0x01
        XCTAssertThrowsError(try Gzip.decompress(data: data)) { error in
            XCTAssertEqual(error as? Gzip.Error, .invalidData)
        }
    }

    func testExtraFieldLengthIsLittleEndian() throws {
        let plain = try sample()
        // Rebuild with FEXTRA set and a 3-byte extra field (XLEN = 03 00).
        var data = Data(plain[0..<10])
        data[3] |= 0x04
        data.append(contentsOf: [0x03, 0x00, 0xAA, 0xBB, 0xCC])
        data.append(plain[10...])
        XCTAssertEqual(try Gzip.decompress(data: data), try Gzip.decompress(data: plain))
    }

    func testDecompressesSlice() throws {
        let plain = try sample()
        let padded = Data([0x00, 0x00]) + plain
        XCTAssertEqual(try Gzip.decompress(data: padded[2...]), try Gzip.decompress(data: plain))
    }
}
