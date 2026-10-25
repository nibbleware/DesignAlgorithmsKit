//
//  BinaryReaderTests.swift
//  DesignAlgorithmsKitTests
//

import XCTest
@testable import DesignAlgorithmsKit

final class DataReaderTests: XCTestCase {
    func testMixedEndianness() throws {
        let reader = DataReader(data: Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06]))
        XCTAssertEqual(try reader.readUInt16LE(), 0x0201)
        XCTAssertEqual(try reader.readUInt32BE(), 0x0304_0506)
        XCTAssertEqual(reader.bytesRemaining, 0)
        XCTAssertEqual(reader.offset, 6)
    }

    func testAllReaders() throws {
        let reader = DataReader(data: Data([0xAA, 0x01, 0x02, 0x01, 0x02, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0xEE, 0xFF]))
        XCTAssertEqual(try reader.readUInt8(), 0xAA)
        XCTAssertEqual(try reader.readUInt16LE(), 0x0201)
        XCTAssertEqual(try reader.readUInt16BE(), 0x0102)
        XCTAssertEqual(try reader.readUInt32LE(), 0x0403_0201)
        XCTAssertEqual(try reader.readUInt32BE(), 0x0102_0304)
        XCTAssertEqual(try reader.readData(length: 2), Data([0xEE, 0xFF]))
        XCTAssertFalse(reader.hasBytesAvailable(1))
        XCTAssertTrue(reader.hasBytesAvailable(0))
    }

    func testShortReadThrowsAndDoesNotAdvance() {
        let reader = DataReader(data: Data([0x01, 0x02]))
        XCTAssertThrowsError(try reader.readUInt32LE()) { error in
            XCTAssertEqual(error as? BinaryReadError, .outOfBounds(offset: 0, count: 4, available: 2))
        }
        XCTAssertEqual(reader.offset, 0)
        XCTAssertThrowsError(try reader.readData(length: 3))
        XCTAssertThrowsError(try reader.readData(length: -1))
        XCTAssertEqual(reader.offset, 0)
    }

    func testSeek() throws {
        let reader = DataReader(data: Data([0x00, 0x11, 0x22]))
        try reader.seek(to: 2)
        XCTAssertEqual(try reader.readUInt8(), 0x22)
        try reader.seek(to: 3)
        XCTAssertEqual(reader.bytesRemaining, 0)
        XCTAssertThrowsError(try reader.seek(to: 4))
        XCTAssertThrowsError(try reader.seek(to: -1))
    }

    func testSlice() throws {
        let data = Data([0x00, 0x11, 0x22, 0x33])
        let reader = DataReader(data: data[2...])
        XCTAssertEqual(try reader.readUInt8(), 0x22)
        XCTAssertEqual(reader.bytesRemaining, 1)
        XCTAssertEqual(try reader.readData(length: 1), Data([0x33]))
    }
}

final class BinaryDataReaderTests: XCTestCase {
    private let bytes = Data([0x12, 0x34, 0x56, 0x78, 0x9A])

    func testNamedReaders() {
        XCTAssertEqual(BinaryDataReader.readUInt16BE(from: bytes, at: 0), 0x1234)
        XCTAssertEqual(BinaryDataReader.readUInt16LE(from: bytes, at: 0), 0x3412)
        XCTAssertEqual(BinaryDataReader.readUInt32BE(from: bytes, at: 1), 0x3456_789A)
        XCTAssertEqual(BinaryDataReader.readUInt32LE(from: bytes, at: 1), 0x9A78_5634)
        XCTAssertEqual(BinaryDataReader.readInt16BE(from: Data([0xFF, 0xFE]), at: 0), -2)
        XCTAssertEqual(BinaryDataReader.readInt16LE(from: Data([0xFE, 0xFF]), at: 0), -2)
        XCTAssertEqual(BinaryDataReader.readInt32BE(from: Data([0xFF, 0xFF, 0xFF, 0xFE]), at: 0), -2)
        XCTAssertEqual(BinaryDataReader.readInt32LE(from: Data([0xFE, 0xFF, 0xFF, 0xFF]), at: 0), -2)
        XCTAssertEqual(BinaryDataReader.readUInt8(from: bytes, at: 4), 0x9A)
    }

    func testOutOfRangeAndNegativeOffsetsReturnZero() {
        XCTAssertEqual(BinaryDataReader.readUInt32LE(from: bytes, at: -1), 0)
        XCTAssertEqual(BinaryDataReader.readUInt32LE(from: bytes, at: 2), 0)
        XCTAssertEqual(BinaryDataReader.readUInt8(from: bytes, at: 5), 0)
        XCTAssertEqual(BinaryDataReader.readUInt16BE(from: bytes, at: Int.max), 0)
        XCTAssertEqual(BinaryDataReader.readUInt16BE(from: bytes, at: Int.min), 0)
    }

    func testCheckedReadThrows() {
        XCTAssertThrowsError(try BinaryDataReader.read(UInt16.self, from: Data([0]), at: 0, endian: .little)) { error in
            XCTAssertEqual(error as? BinaryReadError, .outOfBounds(offset: 0, count: 2, available: 1))
        }
        XCTAssertThrowsError(try BinaryDataReader.read(UInt8.self, from: bytes, at: -3, endian: .big)) { error in
            XCTAssertEqual(error as? BinaryReadError, .outOfBounds(offset: -3, count: 1, available: 0))
        }
        XCTAssertEqual(try BinaryDataReader.read(UInt64.self, from: Data([1, 0, 0, 0, 0, 0, 0, 0]), at: 0, endian: .little), 1)
    }

    func testSliceOffsetsAreRelative() {
        let slice = bytes[1...]
        XCTAssertEqual(BinaryDataReader.readUInt16BE(from: slice, at: 0), 0x3456)
        XCTAssertEqual(BinaryDataReader.readUInt8(from: slice, at: 3), 0x9A)
        XCTAssertEqual(BinaryDataReader.readUInt8(from: slice, at: 4), 0)
    }

    func testWriters() throws {
        var data = Data(count: 6)
        XCTAssertTrue(BinaryDataReader.writeUInt16BE(0x1234, to: &data, at: 0))
        XCTAssertTrue(BinaryDataReader.writeUInt32LE(0xAABB_CCDD, to: &data, at: 2))
        XCTAssertEqual(data, Data([0x12, 0x34, 0xDD, 0xCC, 0xBB, 0xAA]))
        XCTAssertTrue(BinaryDataReader.writeInt32BE(-2, to: &data, at: 2))
        XCTAssertEqual(BinaryDataReader.readInt32BE(from: data, at: 2), -2)
        XCTAssertTrue(BinaryDataReader.writeInt32LE(-3, to: &data, at: 2))
        XCTAssertEqual(BinaryDataReader.readInt32LE(from: data, at: 2), -3)
        XCTAssertTrue(BinaryDataReader.writeUInt16LE(0x0102, to: &data, at: 4))
        XCTAssertTrue(BinaryDataReader.writeUInt32BE(1, to: &data, at: 0))
        XCTAssertEqual(BinaryDataReader.readUInt32BE(from: data, at: 0), 1)

        let before = data
        XCTAssertFalse(BinaryDataReader.writeUInt32LE(1, to: &data, at: 3))
        XCTAssertFalse(BinaryDataReader.writeUInt16BE(1, to: &data, at: -1))
        XCTAssertEqual(data, before)
        XCTAssertThrowsError(try BinaryDataReader.write(UInt32(1), to: &data, at: 4, endian: .big))
    }
}

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
}
