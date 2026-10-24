//
//  Zlib.swift
//  DesignAlgorithmsKit
//
//  In-memory zlib, gzip and raw DEFLATE compression using the system zlib.
//

import Foundation
import zlib

/// Errors thrown by ``Zlib``.
public enum ZlibError: Error, Equatable, Sendable {
    /// zlib rejected the stream parameters (for example invalid window bits or level).
    case initializationFailed
    /// zlib reported an error, or the input stream was corrupt or truncated.
    case processingFailed(message: String)
    /// zlib could not allocate memory.
    case memoryAllocationFailed
}

/// A generic binding to the system zlib for in-memory compression and decompression.
///
/// The stream framing is selected by window bits, as in zlib's `deflateInit2`/`inflateInit2`:
///
/// | Window bits | Framing |
/// | --- | --- |
/// | `8...15` | zlib (RFC 1950) |
/// | `16 + (8...15)` | gzip (RFC 1952) |
/// | `-8 ... -15` | raw DEFLATE (RFC 1951) |
///
/// ```swift
/// let gz = try Zlib.compress(data: data, framing: .gzip)
/// let raw = try Zlib.decompress(data: deflated, windowBits: -15)
/// ```
public enum Zlib {

    /// Common stream framings and their window bits.
    public enum Framing: Sendable, Equatable, CaseIterable {
        /// zlib header and Adler-32 trailer (window bits 15).
        case zlib
        /// gzip header and CRC-32 trailer (window bits 31).
        case gzip
        /// Raw DEFLATE without header or trailer (window bits -15).
        case rawDeflate

        /// The zlib window bits value for this framing.
        public var windowBits: Int {
            switch self {
            case .zlib: return 15
            case .gzip: return 15 + 16
            case .rawDeflate: return -15
            }
        }
    }

    /// zlib's default compression level (`Z_DEFAULT_COMPRESSION`).
    public static let defaultCompressionLevel: Int32 = Z_DEFAULT_COMPRESSION

    /// Size of the output buffer used per zlib call.
    private static let bufferSize = 64 * 1024

    /// Largest input slice handed to zlib per call (`avail_in` is 32-bit).
    private static let maxInputChunk = 1 << 30

    // MARK: - Framing convenience

    /// Compresses `data` with the given framing.
    public static func compress(data: Data, framing: Framing, level: Int32 = defaultCompressionLevel) throws -> Data {
        try compress(data: data, windowBits: framing.windowBits, level: level)
    }

    /// Decompresses `data` with the given framing.
    public static func decompress(data: Data, framing: Framing) throws -> Data {
        try decompress(data: data, windowBits: framing.windowBits)
    }

    // MARK: - Window bits API

    /// Compresses `data`.
    /// - Parameters:
    ///   - data: The bytes to compress. Empty input produces a valid, empty stream.
    ///   - windowBits: Framing selector (15 zlib, 31 gzip, -15 raw DEFLATE). Defaults to gzip.
    ///   - level: Compression level 0-9, or ``defaultCompressionLevel``.
    /// - Returns: The compressed stream.
    /// - Throws: ``ZlibError``.
    public static func compress(data: Data, windowBits: Int = 15 + 16, level: Int32 = defaultCompressionLevel) throws -> Data {
        guard let bits = Int32(exactly: windowBits) else { throw ZlibError.initializationFailed }

        return try withStream { stream in
            let initStatus = deflateInit2_(stream, level, Z_DEFLATED, bits, 8, Z_DEFAULT_STRATEGY,
                                           ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
            try check(initStatus)
            defer { deflateEnd(stream) }

            var output = Data()
            output.reserveCapacity(max(data.count / 2, 64))
            var buffer = [UInt8](repeating: 0, count: bufferSize)

            try data.withUnsafeBytes { (input: UnsafeRawBufferPointer) in
                let base = input.bindMemory(to: Bytef.self).baseAddress
                let total = input.count
                var offset = 0
                var status: Int32 = Z_OK

                repeat {
                    if stream.pointee.avail_in == 0, offset < total, let base {
                        let count = min(total - offset, maxInputChunk)
                        stream.pointee.next_in = UnsafeMutablePointer(mutating: base + offset)
                        stream.pointee.avail_in = UInt32(count)
                        offset += count
                    }
                    let flush = offset == total ? Z_FINISH : Z_NO_FLUSH

                    let produced = buffer.withUnsafeMutableBufferPointer { out -> Int in
                        stream.pointee.next_out = out.baseAddress
                        stream.pointee.avail_out = UInt32(out.count)
                        status = deflate(stream, flush)
                        return out.count - Int(stream.pointee.avail_out)
                    }
                    if produced > 0 { output.append(contentsOf: buffer[0..<produced]) }

                    if status == Z_BUF_ERROR && produced == 0 && stream.pointee.avail_in == 0 && offset == total {
                        throw ZlibError.processingFailed(message: "Deflate made no progress")
                    }
                    if status != Z_OK && status != Z_STREAM_END && status != Z_BUF_ERROR {
                        try check(status)
                    }
                } while status != Z_STREAM_END
            }
            return output
        }
    }

    /// Decompresses `data`.
    /// - Parameters:
    ///   - data: The compressed stream. Empty input returns empty output. Bytes after the end of the stream are ignored.
    ///   - windowBits: Framing selector (15 zlib, 31 gzip, -15 raw DEFLATE, 47 zlib-or-gzip). Defaults to gzip.
    /// - Returns: The decompressed bytes.
    /// - Throws: ``ZlibError`` when the stream is corrupt or truncated.
    public static func decompress(data: Data, windowBits: Int = 15 + 16) throws -> Data {
        guard !data.isEmpty else { return Data() }
        guard let bits = Int32(exactly: windowBits) else { throw ZlibError.initializationFailed }

        return try withStream { stream in
            let initStatus = inflateInit2_(stream, bits, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
            try check(initStatus)
            defer { inflateEnd(stream) }

            var output = Data()
            output.reserveCapacity(data.count * 2)
            var buffer = [UInt8](repeating: 0, count: bufferSize)

            try data.withUnsafeBytes { (input: UnsafeRawBufferPointer) in
                guard let base = input.bindMemory(to: Bytef.self).baseAddress else { return }
                let total = input.count
                var offset = 0
                var status: Int32 = Z_OK

                repeat {
                    if stream.pointee.avail_in == 0 {
                        guard offset < total else {
                            throw ZlibError.processingFailed(message: "Truncated stream")
                        }
                        let count = min(total - offset, maxInputChunk)
                        stream.pointee.next_in = UnsafeMutablePointer(mutating: base + offset)
                        stream.pointee.avail_in = UInt32(count)
                        offset += count
                    }

                    let produced = buffer.withUnsafeMutableBufferPointer { out -> Int in
                        stream.pointee.next_out = out.baseAddress
                        stream.pointee.avail_out = UInt32(out.count)
                        status = inflate(stream, Z_NO_FLUSH)
                        return out.count - Int(stream.pointee.avail_out)
                    }
                    if produced > 0 { output.append(contentsOf: buffer[0..<produced]) }

                    switch status {
                    case Z_OK, Z_STREAM_END:
                        break
                    case Z_BUF_ERROR:
                        // No progress possible: only legitimate when more input is still to come.
                        if stream.pointee.avail_in == 0 && offset == total {
                            throw ZlibError.processingFailed(message: "Truncated stream")
                        }
                    case Z_NEED_DICT:
                        throw ZlibError.processingFailed(message: "Stream requires a preset dictionary")
                    default:
                        try check(status)
                    }
                } while status != Z_STREAM_END
            }
            return output
        }
    }

    // MARK: - Helpers

    /// Runs `body` with a heap-allocated, zero-initialized `z_stream`.
    /// zlib keeps a back-pointer to the stream, so it must not move between calls.
    private static func withStream<R>(_ body: (UnsafeMutablePointer<z_stream>) throws -> R) throws -> R {
        let stream = UnsafeMutablePointer<z_stream>.allocate(capacity: 1)
        stream.initialize(to: z_stream())
        defer {
            stream.deinitialize(count: 1)
            stream.deallocate()
        }
        return try body(stream)
    }

    /// Maps a zlib status to ``ZlibError``; `Z_OK` and `Z_STREAM_END` pass.
    private static func check(_ status: Int32) throws {
        switch status {
        case Z_OK, Z_STREAM_END:
            return
        case Z_MEM_ERROR:
            throw ZlibError.memoryAllocationFailed
        case Z_STREAM_ERROR, Z_VERSION_ERROR:
            throw ZlibError.initializationFailed
        case Z_DATA_ERROR:
            throw ZlibError.processingFailed(message: "Corrupt stream (Z_DATA_ERROR)")
        default:
            throw ZlibError.processingFailed(message: "zlib error \(status)")
        }
    }
}
