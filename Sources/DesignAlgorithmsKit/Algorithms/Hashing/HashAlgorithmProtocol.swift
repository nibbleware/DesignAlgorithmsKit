//
//  HashAlgorithmProtocol.swift
//  DesignAlgorithmsKit
//
//  Hash Algorithm Protocol - Base protocol for hash algorithms
//

import Foundation

#if !canImport(CryptoKit)
#error("DesignAlgorithmsKit needs CryptoKit for its digests; it builds only for Apple platforms.")
#endif

/// Protocol for hash algorithms
public protocol HashAlgorithmProtocol {
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

public extension HashAlgorithmProtocol {
    /// Default implementation for string hashing
    /// - Parameter string: String to hash
    /// - Returns: Hash value as Data, or empty Data if UTF-8 conversion fails
    /// - Note: UTF-8 conversion failure returns empty Data, which will hash to a valid hash value.
    ///   This path is testable by creating strings that fail UTF-8 conversion (rare but possible).
    static func hash(string: String) -> Data {
        guard let data = string.data(using: .utf8) else {
            // UTF-8 conversion failed - return hash of empty data
            // This is a valid fallback that ensures we always return a hash
            return hash(data: Data())
        }
        return hash(data: data)
    }
}

/// SHA-256 hash algorithm (CryptoKit, through ``SHA256Strategy``)
public enum SHA256: HashAlgorithmProtocol {
    public static let name = "SHA-256"
    
    public static func hash(data: Data) -> Data {
        SHA256Strategy().compute(data: data)
    }
}
