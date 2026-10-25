// DesignAlgorithmsKit
// SHA-256 Hash Strategy

import Foundation
import CryptoKit

/// Strategy for SHA-256 hashing
public struct SHA256Strategy: HashStrategy {
    public static let algorithm: HashAlgorithm = .sha256
    
    public init() {}
    
    public func compute(data: Data) -> Data {
        let digest = CryptoKit.SHA256.hash(data: data)
        return Data(digest)
    }
}
