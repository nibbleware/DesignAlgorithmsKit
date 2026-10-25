import Foundation

/// Lightweight ULID generator used for portable identifiers.
/// - SeeAlso: [ULID Specification](https://github.com/ulid/spec)
public struct ULID: Sendable, Equatable, Hashable, Codable, CustomStringConvertible {
    private static let encoding = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ")
    private static let decoding: [Character: UInt8] = {
        var table: [Character: UInt8] = [:]
        for (index, char) in encoding.enumerated() {
            table[char] = UInt8(index)
        }
        return table
    }()

    private let bytes: [UInt8] // 16 bytes

    public init(date: Date = Date(), randomBytes: [UInt8]? = nil) {
        let timestamp = UInt64(date.timeIntervalSince1970 * 1000)
        var data = [UInt8](repeating: 0, count: 16)

        for i in stride(from: 5, through: 0, by: -1) {
            data[5 - i] = UInt8((timestamp >> (i * 8)) & 0xFF)
        }

        var randomData = randomBytes ?? (0..<10).map { _ in UInt8.random(in: 0...255) }
        if randomData.count != 10 {
            randomData = Array(randomData.prefix(10))
            if randomData.count < 10 {
                randomData.append(contentsOf: Array(repeating: 0, count: 10 - randomData.count))
            }
        }
        data.replaceSubrange(6..<16, with: randomData)
        self.bytes = data
    }

    /// Parses the ULID-specification text form (case-insensitive). Returns nil for strings that
    /// are not 26 characters, use characters outside the Crockford alphabet, or start above `7`.
    public init?(string: String) {
        guard let decoded = ULID.decode(string: string) else {
            return nil
        }
        self.bytes = decoded
    }

    /// Parses text written by DesignAlgorithmsKit 1.10.x and earlier, which put the 2 padding bits
    /// at the end instead of the front. Use it to migrate stored IDs: the bytes are unchanged and
    /// `string` then gives the specification form.
    public init?(legacyString: String) {
        guard let decoded = ULID.decodeLegacy(string: legacyString) else {
            return nil
        }
        self.bytes = decoded
    }

    public var description: String {
        ULID.encode(bytes: bytes)
    }

    public var string: String { description }

    // MARK: Codable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        guard let decoded = ULID(string: value) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ULID string.")
        }
        self = decoded
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    // MARK: Helpers

    /// 130 bits (2 zero padding bits, then the 128-bit value) as 26 five-bit characters.
    private static func encode(bytes: [UInt8]) -> String {
        precondition(bytes.count == 16, "ULID must be 16 bytes.")
        var output: [Character] = []
        output.reserveCapacity(26)
        var buffer = 0
        var bitsLeft = 2 // leading padding bits

        for byte in bytes {
            buffer = ((buffer << 8) | Int(byte)) & 0x1FFF
            bitsLeft += 8
            while bitsLeft >= 5 {
                output.append(encoding[(buffer >> (bitsLeft - 5)) & 0x1F])
                bitsLeft -= 5
            }
        }
        return String(output)
    }

    private static func decode(string: String) -> [UInt8]? {
        let values = digits(of: string)
        guard let values, let first = values.first, first <= 7 else { return nil }
        // The first character holds the top 3 bits; the other 25 hold 5 bits each.
        var output: [UInt8] = []
        output.reserveCapacity(16)
        var buffer = Int(first)
        var bitsLeft = 3

        for value in values.dropFirst() {
            buffer = ((buffer << 5) | Int(value)) & 0x1FFF
            bitsLeft += 5
            if bitsLeft >= 8 {
                output.append(UInt8((buffer >> (bitsLeft - 8)) & 0xFF))
                bitsLeft -= 8
            }
        }
        return output.count == 16 ? output : nil
    }

    /// The ≤ 1.10.x layout: 5-bit groups from the most significant bit, 2 trailing padding bits.
    private static func decodeLegacy(string: String) -> [UInt8]? {
        guard let values = digits(of: string) else { return nil }
        var output: [UInt8] = []
        output.reserveCapacity(16)
        var buffer = 0
        var bitsLeft = 0

        for value in values {
            buffer = ((buffer << 5) | Int(value)) & 0x1FFF
            bitsLeft += 5
            if bitsLeft >= 8 {
                output.append(UInt8((buffer >> (bitsLeft - 8)) & 0xFF))
                bitsLeft -= 8
            }
        }
        return output.count == 16 ? output : nil
    }

    /// Crockford base-32 digit values of a 26-character string, or nil.
    private static func digits(of string: String) -> [UInt8]? {
        guard string.count == 26 else { return nil }
        var values: [UInt8] = []
        values.reserveCapacity(26)
        for char in string.uppercased() {
            guard let value = decoding[char] else { return nil }
            values.append(value)
        }
        return values
    }
}
