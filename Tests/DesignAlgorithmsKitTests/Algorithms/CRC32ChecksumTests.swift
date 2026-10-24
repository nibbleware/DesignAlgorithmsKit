import XCTest
@testable import DesignAlgorithmsKit

final class CRC32ChecksumTests: XCTestCase {

    func testCheckValue() {
        XCTAssertEqual(CRC32Checksum.checksum(Data("123456789".utf8)), 0xCBF43926)
    }

    func testEmpty() {
        XCTAssertEqual(CRC32Checksum.checksum(Data()), 0)
        XCTAssertEqual(CRC32Checksum.initialValue, 0)
    }

    func testIncremental() {
        let first = CRC32Checksum.checksum(Data("1234".utf8))
        XCTAssertEqual(CRC32Checksum.update(first, with: Data("56789".utf8)), 0xCBF43926)
        XCTAssertEqual(CRC32Checksum.update(first, with: Data()), first)
    }

    func testStrategyUsesSameValueBigEndian() {
        let data = Data("123456789".utf8)
        XCTAssertEqual(CRC32Strategy().compute(data: data), Data([0xCB, 0xF4, 0x39, 0x26]))
        XCTAssertEqual(HashComputation.computeCRC32(data: data), Data([0xCB, 0xF4, 0x39, 0x26]))
    }

    func testSlicedData() {
        let whole = Data("xx123456789".utf8)
        XCTAssertEqual(CRC32Checksum.checksum(whole.dropFirst(2)), 0xCBF43926)
    }
}
