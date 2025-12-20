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

    public init?(string: String) {
        guard let decoded = ULID.decode(string: string) else {
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

    private static func encode(bytes: [UInt8]) -> String {
        precondition(bytes.count == 16, "ULID must be 16 bytes.")
        var output: [Character] = []
        var buffer = 0
        var bitsLeft = 0

        for byte in bytes {
            buffer = (buffer << 8) | Int(byte)
            bitsLeft += 8
            while bitsLeft >= 5 {
                let index = (buffer >> (bitsLeft - 5)) & 0x1F
                output.append(encoding[index])
                bitsLeft -= 5
            }
        }

        if bitsLeft > 0 {
            let index = (buffer << (5 - bitsLeft)) & 0x1F
            output.append(encoding[index])
        }

        while output.count < 26 {
            output.append(encoding[0])
        }

        return String(output.prefix(26))
    }

    private static func decode(string: String) -> [UInt8]? {
        guard string.count == 26 else { return nil }
        var output: [UInt8] = []
        var buffer = 0
        var bitsLeft = 0

        for char in string.uppercased() {
            guard let value = decoding[char] else { return nil }
            buffer = (buffer << 5) | Int(value)
            bitsLeft += 5

            if bitsLeft >= 8 {
                let byte = UInt8((buffer >> (bitsLeft - 8)) & 0xFF)
                output.append(byte)
                bitsLeft -= 8
            }
        }

        if output.count != 16 {
            return nil
        }
        return output
    }
}
