//
//  UUIDv5Tests.swift
//  DesignAlgorithmsKitTests
//
//  Tests for UUIDv5 generation against known vectors
//

import XCTest
@testable import DesignAlgorithmsKit

final class UUIDv5Tests: XCTestCase {
    
    // Known test vectors for UUID v5
    // Namespace: DNS (6ba7b810-9dad-11d1-80b4-00c04fd430c8)
    // Name: "python.org"
    // Expected: 886313e1-3b8a-5372-9b90-0c9aee199e5d
    func testPythonOrgVector() {
        let name = "python.org"
        let uuid = UUIDv5Generator.generate(for: name)
        
        XCTAssertEqual(uuid.uuidString.lowercased(), "886313e1-3b8a-5372-9b90-0c9aee199e5d")
    }
    
    // Namespace: DNS
    // Name: "example.com"
    // Expected: cfbff0d1-9375-5685-968c-48ce8b15ae17
    func testExampleComVector() {
        let name = "example.com"
        let uuid = UUIDv5Generator.generate(for: name)
        
        XCTAssertEqual(uuid.uuidString.lowercased(), "cfbff0d1-9375-5685-968c-48ce8b15ae17")
    }
    
    func testDeterminism() {
        let name = "random-slug-123"
        let uuid1 = UUIDv5Generator.generate(for: name)
        let uuid2 = UUIDv5Generator.generate(for: name)
        
        XCTAssertEqual(uuid1, uuid2)
    }
    
    func testDistinctness() {
        let uuid1 = UUIDv5Generator.generate(for: "slug-A")
        let uuid2 = UUIDv5Generator.generate(for: "slug-B")
        
        XCTAssertNotEqual(uuid1, uuid2)
    }
    
    func testCustomNamespace() {
        // Test with a custom namespace
        // Namespace: 00000000-0000-0000-0000-000000000000
        // Name: "foo"
        // Expected UUIDv5 (SHA1 of 16 zero bytes + "foo")
        // SHA1(00...00 + 666f6f) = d44a7f05-0f0c-f3c7-124b-3d607612c75d...
        // UUID: d44a7f05-0f0c-53c7-924b-3d607612c75d
        
        let customNS = UUID(uuid: (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0))
        let uuid = UUIDv5Generator.generate(namespace: customNS, name: "foo")
        
        // Version 5 check
        // 5 is 0101. 
        // Byte 6 should be 0x5...
        // Variant check (Byte 8 top 2 bits 10)
        
        let str = uuid.uuidString.lowercased()
        
        // Check version digit (13th hex char is index 14 in string "x-x-x-x-x")
        // UUID String: 8-4-4-4-12
        // chars: 01234567-9012-4567-9012-...
        // Indices:
        // 0-7 (8 chars)
        // 9-12 (4 chars)
        // 14-17 (4 chars) -> Version is at index 14
        
        let versionChar = str[str.index(str.startIndex, offsetBy: 14)]
        XCTAssertEqual(versionChar, "5", "Version must be 5")
        
        // Variant check
        // Index 19 is the variant. 8, 9, a, or b (for RFC 4122 variant 10xx)
        let variantChar = str[str.index(str.startIndex, offsetBy: 19)]
        let validVariants: Set<Character> = ["8", "9", "a", "b"]
        XCTAssertTrue(validVariants.contains(variantChar), "Variant must be RFC 4122 compliant")
    }
}
