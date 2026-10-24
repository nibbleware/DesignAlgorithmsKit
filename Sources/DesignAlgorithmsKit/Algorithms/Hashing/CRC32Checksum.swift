//
//  CRC32Checksum.swift
//  DesignAlgorithmsKit
//
//  CRC-32 (IEEE 802.3) as an integer, backed by the system zlib.
//

import Foundation
import zlib

/// CRC-32 (IEEE 802.3, the checksum used by gzip, ZIP and PNG) as a `UInt32`.
///
/// ```swift
/// let crc = CRC32Checksum.checksum(data)
/// // Incremental: same result as checksumming everything at once
/// var running = CRC32Checksum.initialValue
/// running = CRC32Checksum.update(running, with: part1)
/// running = CRC32Checksum.update(running, with: part2)
/// ```
public enum CRC32Checksum {
    /// The CRC of empty input; the starting value for ``update(_:with:)``.
    public static let initialValue: UInt32 = 0

    /// Returns the CRC-32 of `data`.
    public static func checksum(_ data: Data) -> UInt32 {
        update(initialValue, with: data)
    }

    /// Continues `crc` (a previous result, or ``initialValue``) over `data`.
    public static func update(_ crc: UInt32, with data: Data) -> UInt32 {
        data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> UInt32 in
            guard let base = buffer.bindMemory(to: Bytef.self).baseAddress else { return crc }
            var value = uLong(crc)
            var offset = 0
            let chunk = 1 << 30
            while offset < buffer.count {
                let count = min(buffer.count - offset, chunk)
                value = crc32(value, base + offset, uInt(count))
                offset += count
            }
            return UInt32(truncatingIfNeeded: value)
        }
    }
}
