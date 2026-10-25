import Foundation

/// Reads and writes integers at an offset in `Data`, in big- or little-endian byte order.
///
/// Offsets are relative to the data's start index, and fields are read byte by byte, so
/// slices and unaligned offsets are fine.
///
/// - The named readers (`readUInt32LE(from:at:)` and so on) return 0, and the named writers
///   return `false`, when the offset is negative or the field does not fit. They never trap.
/// - ``read(_:from:at:endian:)`` and ``write(_:to:at:endian:)`` throw
///   ``BinaryReadError/outOfBounds(offset:count:available:)`` instead, for callers that must
///   tell a missing field from a real 0.
public enum BinaryDataReader {

    // MARK: - Checked

    /// Reads a `T` at `offset`.
    public static func read<T: FixedWidthInteger>(
        _ type: T.Type,
        from data: Data,
        at offset: Int,
        endian: ByteOrder
    ) throws -> T {
        let size = MemoryLayout<T>.size
        try checkBounds(offset: offset, count: size, dataCount: data.count)
        let start = data.startIndex + offset
        var value: T = 0
        for index in 0..<size {
            let byte = T(truncatingIfNeeded: data[start + index])
            let shift = endian == .little ? index * 8 : (size - 1 - index) * 8
            value |= byte << shift
        }
        return value
    }

    /// Writes `value` at `offset`.
    public static func write<T: FixedWidthInteger>(
        _ value: T,
        to data: inout Data,
        at offset: Int,
        endian: ByteOrder
    ) throws {
        let size = MemoryLayout<T>.size
        try checkBounds(offset: offset, count: size, dataCount: data.count)
        let start = data.startIndex + offset
        for index in 0..<size {
            let shift = endian == .little ? index * 8 : (size - 1 - index) * 8
            data[start + index] = UInt8(truncatingIfNeeded: value >> shift)
        }
    }

    // MARK: - Big-endian reads (0 when out of range)

    public static func readInt32BE(from data: Data, at offset: Int) -> Int32 {
        lenient(Int32.self, data, offset, .big)
    }

    public static func readUInt32BE(from data: Data, at offset: Int) -> UInt32 {
        lenient(UInt32.self, data, offset, .big)
    }

    public static func readInt16BE(from data: Data, at offset: Int) -> Int16 {
        lenient(Int16.self, data, offset, .big)
    }

    public static func readUInt16BE(from data: Data, at offset: Int) -> UInt16 {
        lenient(UInt16.self, data, offset, .big)
    }

    // MARK: - Little-endian reads (0 when out of range)

    public static func readInt32LE(from data: Data, at offset: Int) -> Int32 {
        lenient(Int32.self, data, offset, .little)
    }

    public static func readUInt32LE(from data: Data, at offset: Int) -> UInt32 {
        lenient(UInt32.self, data, offset, .little)
    }

    public static func readInt16LE(from data: Data, at offset: Int) -> Int16 {
        lenient(Int16.self, data, offset, .little)
    }

    public static func readUInt16LE(from data: Data, at offset: Int) -> UInt16 {
        lenient(UInt16.self, data, offset, .little)
    }

    public static func readUInt8(from data: Data, at offset: Int) -> UInt8 {
        lenient(UInt8.self, data, offset, .little)
    }

    // MARK: - Writes (false when out of range)

    @discardableResult
    public static func writeInt32BE(_ value: Int32, to data: inout Data, at offset: Int) -> Bool {
        lenientWrite(value, &data, offset, .big)
    }

    @discardableResult
    public static func writeInt32LE(_ value: Int32, to data: inout Data, at offset: Int) -> Bool {
        lenientWrite(value, &data, offset, .little)
    }

    @discardableResult
    public static func writeUInt32BE(_ value: UInt32, to data: inout Data, at offset: Int) -> Bool {
        lenientWrite(value, &data, offset, .big)
    }

    @discardableResult
    public static func writeUInt32LE(_ value: UInt32, to data: inout Data, at offset: Int) -> Bool {
        lenientWrite(value, &data, offset, .little)
    }

    @discardableResult
    public static func writeUInt16BE(_ value: UInt16, to data: inout Data, at offset: Int) -> Bool {
        lenientWrite(value, &data, offset, .big)
    }

    @discardableResult
    public static func writeUInt16LE(_ value: UInt16, to data: inout Data, at offset: Int) -> Bool {
        lenientWrite(value, &data, offset, .little)
    }

    // MARK: - Internal

    private static func checkBounds(offset: Int, count: Int, dataCount: Int) throws {
        guard offset >= 0, offset <= dataCount, count <= dataCount - offset else {
            let available = (offset >= 0 && offset <= dataCount) ? dataCount - offset : 0
            throw BinaryReadError.outOfBounds(offset: offset, count: count, available: available)
        }
    }

    private static func lenient<T: FixedWidthInteger>(_ type: T.Type, _ data: Data, _ offset: Int, _ endian: ByteOrder) -> T {
        (try? read(type, from: data, at: offset, endian: endian)) ?? 0
    }

    private static func lenientWrite<T: FixedWidthInteger>(_ value: T, _ data: inout Data, _ offset: Int, _ endian: ByteOrder) -> Bool {
        (try? write(value, to: &data, at: offset, endian: endian)) != nil
    }
}
