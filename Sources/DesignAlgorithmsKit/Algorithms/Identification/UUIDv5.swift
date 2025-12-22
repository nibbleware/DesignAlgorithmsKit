//
//  UUIDv5.swift
//  DesignAlgorithmsKit
//
//  UUIDv5 Generation Algorithm (SHA-1 hashing of namespace + name)
//

import Foundation
import CryptoKit

/// Generator for version 5 UUIDs (SHA-1 hashing of namespace + name).
/// Implementation based on RFC 4122.
public enum UUIDv5Generator {
    
    /// The DNS Namespace UUID: 6ba7b810-9dad-11d1-80b4-00c04fd430c8
    public static let dnsNamespace = UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")!
    
    /// Generates a UUIDv5 using the DNS namespace and the provided name string.
    /// - Parameter name: The name to hash (e.g. a slug).
    /// - Returns: A deterministic, repeatable UUID.
    public static func generate(for name: String) -> UUID {
        return uuid(from: dnsNamespace, name: name)
    }
    
    /// Generates a UUIDv5 using a custom namespace and name.
    /// - Parameters:
    ///   - namespace: The namespace UUID.
    ///   - name: The name to hash.
    /// - Returns: A deterministic, repeatable UUID.
    public static func generate(namespace: UUID, name: String) -> UUID {
        return uuid(from: namespace, name: name)
    }
    
    private static func uuid(from namespace: UUID, name: String) -> UUID {
        // UUID layout:
        // octet 0-3: time_low
        // octet 4-5: time_mid
        // octet 6-7: time_hi_and_version
        // octet 8: clock_seq_hi_and_reserved
        // octet 9: clock_seq_low
        // octet 10-15: node
        
        // 1. Convert namespace UUID to bytes (big endian)
        var nsBytes = namespace.uuid
        var nsData = Data(bytes: &nsBytes, count: 16)
        
        // 2. Append name bytes (UTF8)
        guard let nameData = name.data(using: .utf8) else {
            return UUID()
        }
        nsData.append(nameData)
        
        // 3. Hash with SHA-1
        let hash = Insecure.SHA1.hash(data: nsData)
        
        // 4. Truncate to 16 bytes using iterator
        var bytes = Array(hash.makeIterator().prefix(16))
        
        // 5. Set version to 5 (0101) in top 4 bits of octet 6
        bytes[6] = (bytes[6] & 0x0f) | 0x50
        
        // 6. Set variant to RFC 4122 (10) in top 2 bits of octet 8
        bytes[8] = (bytes[8] & 0x3f) | 0x80
        
        // 7. Create UUID from bytes
        let tuple = (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        )
        
        return UUID(uuid: tuple)
    }
}
