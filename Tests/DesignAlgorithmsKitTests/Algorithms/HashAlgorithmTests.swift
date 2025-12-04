//
//  HashAlgorithmTests.swift
//  DesignAlgorithmsKitTests
//
//  Unit tests for Hash Algorithm
//

import XCTest
@testable import DesignAlgorithmsKit

final class HashAlgorithmTests: XCTestCase {
    
    // MARK: - SHA256 Tests
    
    func testSHA256Name() {
        // Then
        XCTAssertEqual(SHA256.name, "SHA-256")
    }
    
    func testSHA256HashData() {
        // Given
        let data = "Hello, World!".data(using: .utf8)!
        
        // When
        let hash1 = SHA256.hash(data: data)
        let hash2 = SHA256.hash(data: data)
        
        // Then
        XCTAssertEqual(hash1.count, 32, "SHA-256 should produce 32 bytes")
        XCTAssertEqual(hash2.count, 32, "SHA-256 should produce 32 bytes")
        XCTAssertEqual(hash1, hash2, "Same input should produce same hash")
    }
    
    func testSHA256HashString() {
        // Given
        let string = "Hello, World!"
        
        // When
        let hash1 = SHA256.hash(string: string)
        let hash2 = SHA256.hash(string: string)
        
        // Then
        XCTAssertEqual(hash1.count, 32, "SHA-256 should produce 32 bytes")
        XCTAssertEqual(hash2.count, 32, "SHA-256 should produce 32 bytes")
        XCTAssertEqual(hash1, hash2, "Same input should produce same hash")
    }
    
    func testSHA256HashDifferentInputs() {
        // Given
        let data1 = "Hello".data(using: .utf8)!
        let data2 = "World".data(using: .utf8)!
        
        // When
        let hash1 = SHA256.hash(data: data1)
        let hash2 = SHA256.hash(data: data2)
        
        // Then
        XCTAssertNotEqual(hash1, hash2, "Different inputs should produce different hashes")
    }
    
    func testSHA256HashEmptyData() {
        // Given
        let emptyData = Data()
        
        // When
        let hash = SHA256.hash(data: emptyData)
        
        // Then
        XCTAssertEqual(hash.count, 32, "Empty data should still produce 32-byte hash")
    }
    
    func testSHA256HashEmptyString() {
        // Given
        let emptyString = ""
        
        // When
        let hash = SHA256.hash(string: emptyString)
        
        // Then
        XCTAssertEqual(hash.count, 32, "Empty string should still produce 32-byte hash")
    }
    
    func testSHA256HashLargeData() {
        // Given
        let largeData = Data(repeating: 0x42, count: 10000)
        
        // When
        let hash = SHA256.hash(data: largeData)
        
        // Then
        XCTAssertEqual(hash.count, 32, "Large data should produce 32-byte hash")
    }
    
    func testSHA256HashConsistency() {
        // Given
        let testCases = [
            "test",
            "Hello, World!",
            "1234567890",
            "The quick brown fox jumps over the lazy dog",
            "Special chars: !@#$%^&*()",
            "Unicode: 🚀🌟✨",
            "Multi\nline\nstring"
        ]
        
        // When/Then
        for testCase in testCases {
            let hash1 = SHA256.hash(string: testCase)
            let hash2 = SHA256.hash(string: testCase)
            XCTAssertEqual(hash1, hash2, "Hash should be consistent for: \(testCase)")
            XCTAssertEqual(hash1.count, 32, "Hash should be 32 bytes for: \(testCase)")
        }
    }
    
    func testSHA256HashUnicodeString() {
        // Given
        let unicodeStrings = [
            "Hello, 世界",
            "مرحبا",
            "Здравствуй",
            "こんにちは",
            "🚀🌟✨"
        ]
        
        // When/Then
        for string in unicodeStrings {
            let hash = SHA256.hash(string: string)
            XCTAssertEqual(hash.count, 32, "Unicode string should produce 32-byte hash: \(string)")
        }
    }
    
    // MARK: - HashAlgorithm Protocol Tests
    
    func testHashAlgorithmProtocolConformance() {
        // Then
        XCTAssertEqual(SHA256.name, "SHA-256")
        
        let testData = "test".data(using: .utf8)!
        let hash = SHA256.hash(data: testData)
        XCTAssertEqual(hash.count, 32)
    }
    
    func testHashAlgorithmStringExtension() {
        // Given
        let string = "test string"
        
        // When
        let hashFromString = SHA256.hash(string: string)
        let hashFromData = SHA256.hash(data: string.data(using: .utf8)!)
        
        // Then
        XCTAssertEqual(hashFromString, hashFromData, "String extension should produce same hash as data")
    }
    
    func testHashAlgorithmInvalidUTF8() {
        // Given
        // Create data that can't be converted to UTF-8 string
        let invalidUTF8Data = Data([0xFF, 0xFE, 0xFD])
        
        // When
        let hash = SHA256.hash(data: invalidUTF8Data)
        
        // Then
        XCTAssertEqual(hash.count, 32, "Invalid UTF-8 data should still produce hash")
    }
    
    func testHashAlgorithmStringExtensionFallback() {
        // Given - Test that the extension fallback (hashing empty data) works correctly
        // Note: Swift's String.data(using: .utf8) rarely returns nil, so we test the fallback
        // behavior by verifying that empty data hashing works, which is what happens
        // when UTF-8 conversion fails in the extension.
        let emptyData = Data()
        let hashFromEmptyData = SHA256.hash(data: emptyData)
        
        // When - Hash empty string (which should convert to empty data)
        let hashFromEmptyString = SHA256.hash(string: "")
        
        // Then - Both should produce valid hashes
        XCTAssertEqual(hashFromEmptyData.count, 32)
        XCTAssertEqual(hashFromEmptyString.count, 32)
        // Empty string should hash to the same as empty data
        XCTAssertEqual(hashFromEmptyString, hashFromEmptyData)
    }
    
    func testHashAlgorithmStringExtensionConsistency() {
        // Given - Verify that the extension correctly converts strings to data
        let testStrings = [
            "normal string",
            "string with émojis 🚀",
            "string with\nnewlines",
            "string with\t tabs"
        ]
        
        // When/Then - Verify extension produces same hash as manual conversion
        for testString in testStrings {
            let hashFromExtension = SHA256.hash(string: testString)
            let hashFromManual = SHA256.hash(data: testString.data(using: .utf8)!)
            XCTAssertEqual(hashFromExtension, hashFromManual, 
                          "Extension should produce same hash as manual conversion for: \(testString)")
        }
    }
}

