//
//  HashAlgorithmTests.swift
//  DesignAlgorithmsKitTests
//
//  Unit tests for Hash Algorithm
//

import XCTest
@testable import DesignAlgorithmsKit

final class HashAlgorithmTests: XCTestCase {
    
    func testCaseIterable() {
        XCTAssertEqual(HashAlgorithm.allCases.count, 4)
        XCTAssertTrue(HashAlgorithm.allCases.contains(.sha256))
        XCTAssertTrue(HashAlgorithm.allCases.contains(.sha1))
        XCTAssertTrue(HashAlgorithm.allCases.contains(.md5))
        XCTAssertTrue(HashAlgorithm.allCases.contains(.crc32))
    }
    
    func testRawValues() {
        XCTAssertEqual(HashAlgorithm.sha256.rawValue, "sha256")
        XCTAssertEqual(HashAlgorithm.sha1.rawValue, "sha1")
        XCTAssertEqual(HashAlgorithm.md5.rawValue, "md5")
        XCTAssertEqual(HashAlgorithm.crc32.rawValue, "crc32")
    }
    
    func testDisplayName() {
        XCTAssertEqual(HashAlgorithm.sha256.displayName, "SHA256")
        XCTAssertEqual(HashAlgorithm.sha1.displayName, "SHA1")
        XCTAssertEqual(HashAlgorithm.md5.displayName, "MD5")
        XCTAssertEqual(HashAlgorithm.crc32.displayName, "CRC32")
    }
    
    func testIsRecommendedForNewHashes() {
        XCTAssertTrue(HashAlgorithm.sha256.isRecommendedForNewHashes)
        XCTAssertFalse(HashAlgorithm.sha1.isRecommendedForNewHashes)
        XCTAssertFalse(HashAlgorithm.md5.isRecommendedForNewHashes)
        XCTAssertFalse(HashAlgorithm.crc32.isRecommendedForNewHashes)
    }
    
    func testIsSuitableForValidation() {
        // All should be true
        XCTAssertTrue(HashAlgorithm.sha256.isSuitableForValidation)
        XCTAssertTrue(HashAlgorithm.sha1.isSuitableForValidation)
        XCTAssertTrue(HashAlgorithm.md5.isSuitableForValidation)
        XCTAssertTrue(HashAlgorithm.crc32.isSuitableForValidation)
    }
    
    func testHashSize() {
        XCTAssertEqual(HashAlgorithm.crc32.hashSize, 4)
        XCTAssertEqual(HashAlgorithm.md5.hashSize, 16)
        XCTAssertEqual(HashAlgorithm.sha1.hashSize, 20)
        XCTAssertEqual(HashAlgorithm.sha256.hashSize, 32)
    }
    
    func testIsSuitableForSmallFiles() {
        // All return true currently
        for algo in HashAlgorithm.allCases {
            XCTAssertTrue(algo.isSuitableForSmallFiles)
        }
    }
    
    func testRecommendedForSmallFiles() {
        XCTAssertEqual(HashAlgorithm.recommendedForSmallFiles, .sha256)
    }
    
    func testRecommendedForMillionsOfFiles() {
        XCTAssertEqual(HashAlgorithm.recommendedForMillionsOfFiles, .sha256)
    }
    
    func testStorageOverheadMB() {
        // Test calculation: (size * count) / (1024*1024)
        // SHA256 (32 bytes) * 1,000,000 files
        // 32,000,000 bytes / 1,048,576 = 30.517... MB
        
        let count = 1_000_000
        let sha256Overhead = HashAlgorithm.sha256.storageOverheadMB(for: count)
        XCTAssertEqual(sha256Overhead, (32.0 * 1_000_000.0) / (1024.0 * 1024.0), accuracy: 0.0001)
        
        // CRC32 (4 bytes) * 1,024 files -> 4 KB -> 0.00390625 MB
        let crc32Overhead = HashAlgorithm.crc32.storageOverheadMB(for: 1024)
        XCTAssertEqual(crc32Overhead, (4.0 * 1024.0) / (1024 * 1024), accuracy: 0.0001)
    }
    
    func testIsSuitableForMillionsOfFiles() {
        XCTAssertTrue(HashAlgorithm.sha256.isSuitableForMillionsOfFiles)
        XCTAssertTrue(HashAlgorithm.sha1.isSuitableForMillionsOfFiles)
        XCTAssertTrue(HashAlgorithm.md5.isSuitableForMillionsOfFiles)
        XCTAssertFalse(HashAlgorithm.crc32.isSuitableForMillionsOfFiles)
    }
}
