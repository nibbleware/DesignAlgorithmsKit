//
//  GitObjectLayout.swift
//  DesignAlgorithmsKit
//
//  Created for DesignAlgorithmsKit
//

import Foundation

/// Git-Style Directory Layout Strategy
///
/// Implements the directory layout strategy used by Git for loose objects,
/// where a content hash is split into a directory (prefix) and filename (remainder).
///
/// Example:
/// Hash: "a1b2c3d4..."
/// Directory: "a1"
/// Filename: "b2c3d4..."
/// Path: "a1/b2c3d4..."
public struct GitObjectLayout {
    
    /// The length of the prefix used for the directory name
    public static let prefixLength = 2
    
    /// Generates the layout components for a given hash.
    /// - Parameter hash: The hex string representation of the hash.
    /// - Returns: A tuple containing the directory, filename, and combined relative path.
    ///            If the hash is too short (<= prefixLength), returns empty directory and the hash as filename.
    public static func layout(for hash: String) -> (directory: String, filename: String, path: String) {
        guard hash.count > Self.prefixLength else {
            return (directory: "", filename: hash, path: hash)
        }
        
        let prefixIndex = hash.index(hash.startIndex, offsetBy: Self.prefixLength)
        let prefix = String(hash[..<prefixIndex])
        let suffix = String(hash[prefixIndex...])
        
        // Ensure path separator is handled by caller or returned as standard relative path
        let path = "\(prefix)/\(suffix)"
        
        return (directory: prefix, filename: suffix, path: path)
    }
    
    /// Generates the relative path for a given hash.
    /// - Parameter hash: The hex string representation of the hash.
    /// - Returns: The relative path string (e.g., "ab/cdef...").
    public static func path(for hash: String) -> String {
        return layout(for: hash).path
    }
}
