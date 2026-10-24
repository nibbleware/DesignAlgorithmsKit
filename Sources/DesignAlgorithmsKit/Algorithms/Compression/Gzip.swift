import Foundation

/// In-memory GZIP (RFC 1952) compression and decompression, built on ``Zlib`` raw DEFLATE.
///
/// For other framings (zlib, raw DEFLATE, custom window bits) use ``Zlib`` directly.
public struct Gzip {
    
    /// Errors that can occur during compression or decompression.
    public enum Error: Swift.Error {
        case compressionFailed
        case decompressionFailed
        case invalidData
    }
    
    /// Compresses data using GZIP algorithm.
    /// - Parameter data: The input data to compress.
    /// - Returns: The compressed data.
    /// - Throws: `Gzip.Error.compressionFailed` if the operation fails.
    public static func compress(data: Data) throws -> Data {
        // GZIP Header (10 bytes)
        // Magic (2), Method (1), Flags (1), MTime (4), XFlags (1), OS (1)
        var result = Data([0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03])
        
        // 1. Compress with ZLIB algorithm (raw deflate) using low-level API
        let rawDeflated = try compressRawDeflate(data)

        // 2. Append to Header
        result.append(rawDeflated)
        
        // 3. Append CRC32 (4 bytes)
        let crc = CRC32Checksum.checksum(data)
        result.append(contentsOf: withUnsafeBytes(of: crc.littleEndian) { Array($0) })
        
        // 4. Append ISIZE (Input Size) modulo 2^32 (4 bytes)
        let isize = UInt32(truncatingIfNeeded: data.count)
        result.append(contentsOf: withUnsafeBytes(of: isize.littleEndian) { Array($0) })
        
        return result
    }
    
    /// Decompresses GZIP compressed data.
    /// - Parameter data: The compressed data (including GZIP header).
    /// - Returns: The uncompressed data.
    /// - Throws: `Gzip.Error.decompressionFailed` or `invalidData`.
    public static func decompress(data: Data) throws -> Data {
        // GZIP Header Validation
        guard data.count >= 18 else { throw Error.invalidData }
        guard data[0] == 0x1f, data[1] == 0x8b else { throw Error.invalidData }
        guard data[2] == 0x08 else { throw Error.decompressionFailed } // Method must be DEFLATE
        
        // Parse Flags
        var parser = DataParser(data: data)
        _ = try parser.readByte() // Magic 1
        _ = try parser.readByte() // Magic 2
        _ = try parser.readByte() // Method
        let flags = try parser.readByte()
        _ = try parser.readBytes(count: 6) // MTime, XFlags, OS
        
        // FEXTRA (0x04)
        if (flags & 0x04) != 0 {
            let xlen = try parser.readUInt16()
            _ = try parser.readBytes(count: Int(xlen))
        }
        
        // FNAME (0x08)
        if (flags & 0x08) != 0 {
            while (try parser.readByte()) != 0 {}
        }
        
        // FCOMMENT (0x10)
        if (flags & 0x10) != 0 {
            while (try parser.readByte()) != 0 {}
        }
        
        // FHCRC (0x02)
        if (flags & 0x02) != 0 {
           _ = try parser.readBytes(count: 2)
        }
        
        let headerSize = parser.offset
        let footerSize = 8
        guard data.count > headerSize + footerSize else { throw Error.invalidData }
        
        let deflatePayload = data.subdata(in: headerSize..<(data.count - footerSize))
        
        return try decompressRawDeflate(deflatePayload)
    }

    // MARK: - Internal Helpers

    private static func compressRawDeflate(_ input: Data) throws -> Data {
        do {
            return try Zlib.compress(data: input, framing: .rawDeflate)
        } catch {
            throw Error.compressionFailed
        }
    }

    private static func decompressRawDeflate(_ input: Data) throws -> Data {
        do {
            return try Zlib.decompress(data: input, framing: .rawDeflate)
        } catch {
            throw Error.decompressionFailed
        }
    }
}

// Helper for parsing binary data
struct DataParser {
    let data: Data
    var offset = 0
    
    mutating func readByte() throws -> UInt8 {
        guard offset < data.count else { throw Gzip.Error.invalidData }
        let b = data[offset]
        offset += 1
        return b
    }
    
    mutating func readBytes(count: Int) throws -> Data {
        guard offset + count <= data.count else { throw Gzip.Error.invalidData }
        let chunk = data.subdata(in: offset..<(offset+count))
        offset += count
        return chunk
    }
    
    mutating func readUInt16() throws -> UInt16 {
        let bytes = try readBytes(count: 2)
        return bytes.withUnsafeBytes { $0.load(as: UInt16.self) }
    }
}
