// DesignAlgorithmsKit
// SHA-1 Hash Strategy

import Foundation
import CryptoKit

/// Strategy for SHA-1 hashing
/// Note: SHA-1 is insecure and should only be used for legacy compatibility
public struct SHA1Strategy: HashStrategy {
    public static let algorithm: HashAlgorithm = .sha1
    
    public init() {}
    
    public func compute(data: Data) -> Data {
        let digest = Insecure.SHA1.hash(data: data)
        return Data(digest)
    }
}
