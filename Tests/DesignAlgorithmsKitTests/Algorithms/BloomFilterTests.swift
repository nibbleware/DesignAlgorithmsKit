//
//  BloomFilterTests.swift
//  DesignAlgorithmsKitTests
//
//  Unit tests for Bloom Filter
//

import XCTest
@testable import DesignAlgorithmsKit

final class BloomFilterTests: XCTestCase {
    func testInsertAndContains() {
        // Given
        let filter = BloomFilter(capacity: 100, falsePositiveRate: 0.01)
        
        // When
        filter.insert("element1")
        filter.insert("element2")
        filter.insert("element3")
        
        // Then
        XCTAssertTrue(filter.contains("element1"))
        XCTAssertTrue(filter.contains("element2"))
        XCTAssertTrue(filter.contains("element3"))
        XCTAssertFalse(filter.contains("element4"))
    }
    
    func testFalsePositiveRate() {
        // Given
        let filter = BloomFilter(capacity: 1000, falsePositiveRate: 0.01)
        
        // When
        for i in 0..<100 {
            filter.insert("element\(i)")
        }
        
        // Then
        let estimatedRate = filter.estimatedFalsePositiveRate()
        XCTAssertGreaterThanOrEqual(estimatedRate, 0.0)
        XCTAssertLessThanOrEqual(estimatedRate, 1.0)
    }
    
    func testFillRatio() {
        // Given
        let filter = BloomFilter(capacity: 100, falsePositiveRate: 0.01)
        
        // When
        filter.insert("element1")
        filter.insert("element2")
        
        // Then
        let ratio = filter.fillRatio()
        XCTAssertGreaterThanOrEqual(ratio, 0.0)
        XCTAssertLessThanOrEqual(ratio, 1.0)
    }
    
    func testClear() {
        // Given
        let filter = BloomFilter(capacity: 100, falsePositiveRate: 0.01)
        filter.insert("element1")
        
        // When
        filter.clear()
        
        // Then
        XCTAssertFalse(filter.contains("element1"))
        XCTAssertEqual(filter.elementCount, 0)
    }
    
    func testMerge() throws {
        // Given
        let filter1 = BloomFilter(capacity: 100, falsePositiveRate: 0.01)
        let filter2 = BloomFilter(capacity: 100, falsePositiveRate: 0.01)
        
        filter1.insert("element1")
        filter2.insert("element2")
        
        // When
        try filter1.merge(filter2)
        
        // Then
        XCTAssertTrue(filter1.contains("element1"))
        XCTAssertTrue(filter1.contains("element2"))
    }
    
    func testMergeIncompatibleFilters() {
        // Given
        let filter1 = BloomFilter(capacity: 100, falsePositiveRate: 0.01)
        let filter2 = BloomFilter(capacity: 200, falsePositiveRate: 0.01)
        
        // When/Then
        XCTAssertThrowsError(try filter1.merge(filter2)) { error in
            if case BloomFilterError.incompatibleFilters = error {
                // Expected error
            } else {
                XCTFail("Unexpected error type")
            }
        }
    }
    
    func testCountingBloomFilter() {
        // Given
        let filter = CountingBloomFilter(capacity: 100, falsePositiveRate: 0.01)
        
        // When
        filter.insert("element1")
        filter.insert("element2")
        
        // Then
        XCTAssertTrue(filter.contains("element1"))
        XCTAssertTrue(filter.contains("element2"))
        
        // When - Remove element
        filter.remove("element1")
        
        // Then
        XCTAssertFalse(filter.contains("element1"))
        XCTAssertTrue(filter.contains("element2"))
    }
    
    func testCountingBloomFilterClear() {
        // Given
        let filter = CountingBloomFilter(capacity: 100, falsePositiveRate: 0.01)
        filter.insert("element1")
        
        // When
        filter.clear()
        
        // Then
        XCTAssertFalse(filter.contains("element1"))
        XCTAssertEqual(filter.elementCount, 0)
    }
}

