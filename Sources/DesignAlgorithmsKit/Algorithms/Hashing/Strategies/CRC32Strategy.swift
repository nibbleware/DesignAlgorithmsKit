// DesignAlgorithmsKit
// CRC32 Hash Strategy

import Foundation

/// Strategy for CRC32 check-summing
public struct CRC32Strategy: HashStrategy {
    public static let algorithm: HashAlgorithm = .crc32
    
    public init() {}
    
    public func compute(data: Data) -> Data {
        let crc = CRC32Checksum.checksum(data)
        return withUnsafeBytes(of: crc.bigEndian) { Data($0) }
    }
}
