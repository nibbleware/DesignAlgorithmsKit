import Foundation

/// Reads binary data sequentially, tracking the offset.
///
/// Offsets are relative to the data's start index, so slices read correctly. A read that
/// runs past the end throws ``BinaryReadError/outOfBounds(offset:count:available:)`` and
/// leaves the offset unchanged.
///
/// ```swift
/// let reader = DataReader(data: header)
/// let magic = try reader.readUInt32BE()
/// let count = try reader.readUInt16LE()
/// ```
public final class DataReader {
    private let data: Data

    /// Current position, from 0 to the data's count.
    public private(set) var offset: Int

    /// - Parameter data: Data to read from
    public init(data: Data) {
        self.data = data
        self.offset = 0
    }

    /// Moves to `newOffset` (0 through the data's count).
    public func seek(to newOffset: Int) throws {
        guard newOffset >= 0 && newOffset <= data.count else {
            throw BinaryReadError.outOfBounds(offset: newOffset, count: 0, available: 0)
        }
        offset = newOffset
    }

    /// Reads `length` bytes.
    public func readData(length: Int) throws -> Data {
        let start = try reserve(length)
        return data.subdata(in: start..<(start + length))
    }

    public func readUInt8() throws -> UInt8 {
        try read(UInt8.self, .little)
    }

    public func readUInt16LE() throws -> UInt16 {
        try read(UInt16.self, .little)
    }

    public func readUInt16BE() throws -> UInt16 {
        try read(UInt16.self, .big)
    }

    public func readUInt32LE() throws -> UInt32 {
        try read(UInt32.self, .little)
    }

    public func readUInt32BE() throws -> UInt32 {
        try read(UInt32.self, .big)
    }

    /// True when at least `count` bytes remain.
    public func hasBytesAvailable(_ count: Int) -> Bool {
        count >= 0 && count <= bytesRemaining
    }

    /// Bytes left after the current offset.
    public var bytesRemaining: Int {
        max(0, data.count - offset)
    }

    // MARK: - Internal

    private func read<T: FixedWidthInteger>(_ type: T.Type, _ endian: ByteOrder) throws -> T {
        let value = try BinaryDataReader.read(type, from: data, at: offset, endian: endian)
        offset += MemoryLayout<T>.size
        return value
    }

    /// Checks that `count` bytes remain, advances past them and returns their absolute start index.
    private func reserve(_ count: Int) throws -> Data.Index {
        guard count >= 0, count <= bytesRemaining else {
            throw BinaryReadError.outOfBounds(offset: offset, count: count, available: bytesRemaining)
        }
        let start = data.startIndex + offset
        offset += count
        return start
    }
}
