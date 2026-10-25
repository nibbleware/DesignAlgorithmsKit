// DesignAlgorithmsKit
// MD5 Hash Strategy

import Foundation
import CryptoKit

/// Strategy for MD5 hashing
/// Note: MD5 is insecure and should only be used for legacy compatibility
public struct MD5Strategy: HashStrategy {
    public static let algorithm: HashAlgorithm = .md5
    
    public init() {}
    
    public func compute(data: Data) -> Data {
        let digest = Insecure.MD5.hash(data: data)
        return Data(digest)
    }
}
