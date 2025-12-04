//
//  HashAlgorithm.swift
//  DesignAlgorithmsKit
//
//  Hash Algorithm Protocol - Base protocol for hash algorithms
//

import Foundation

#if canImport(CryptoKit)
import CryptoKit
#endif

/// Protocol for hash algorithms
public protocol HashAlgorithm {
    /// Algorithm name
    static var name: String { get }
    
    /// Hash data using this algorithm
    /// - Parameter data: Data to hash
    /// - Returns: Hash value as Data
    static func hash(data: Data) -> Data
    
    /// Hash a string using this algorithm
    /// - Parameter string: String to hash
    /// - Returns: Hash value as Data
    static func hash(string: String) -> Data
}

extension HashAlgorithm {
    /// Default implementation for string hashing
    public static func hash(string: String) -> Data {
        guard let data = string.data(using: .utf8) else {
            return Data()
        }
        return hash(data: data)
    }
}

/// SHA-256 hash algorithm
public enum SHA256: HashAlgorithm {
    public static let name = "SHA-256"
    
    public static func hash(data: Data) -> Data {
        #if canImport(CryptoKit)
        let digest = CryptoKit.SHA256.hash(data: data)
        return Data(digest)
        #else
        // Fallback implementation
        // In production, use CommonCrypto or another crypto library
        return fallbackHash(data: data)
        #endif
    }
    
    #if !canImport(CryptoKit)
    /// Fallback hash implementation (simple, not cryptographically secure)
    /// For production use, import CryptoKit or CommonCrypto
    private static func fallbackHash(data: Data) -> Data {
        var hash = Data(count: 32)
        data.withUnsafeBytes { dataBytes in
            hash.withUnsafeMutableBytes { hashBytes in
                // Simple hash (NOT cryptographically secure)
                // This is a placeholder - use CryptoKit in production
                for i in 0..<32 {
                    var value: UInt8 = 0
                    for j in 0..<dataBytes.count {
                        value ^= dataBytes[j] &+ UInt8(i)
                    }
                    hashBytes[i] = value
                }
            }
        }
        return hash
    }
    #endif
}

