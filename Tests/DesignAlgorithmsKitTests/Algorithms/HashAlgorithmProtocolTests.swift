//
//  HashAlgorithmProtocolTests.swift
//  DesignAlgorithmsKitTests
//
//  Unit tests for Hash Algorithm Protocol default implementations
//

import XCTest
@testable import DesignAlgorithmsKit

final class HashAlgorithmProtocolTests: XCTestCase {
    
    struct MockHash: HashAlgorithmProtocol {
        static let name = "Mock"
        
        static func hash(data: Data) -> Data {
            return data
        }
        // Uses default hash(string:) implementation
    }
    
    func testDefaultStringHash() {
        let input = "test"
        let expectedData = input.data(using: .utf8)!
        
        // Should call default implementation which calls hash(data:)
        let result = MockHash.hash(string: input)
        
        XCTAssertEqual(result, expectedData)
    }
    
    func testSHA256Hash() {
        let data = "test".data(using: .utf8)!
        let hash = SHA256.hash(data: data)
        XCTAssertEqual(hash.count, 32)
    }
}
