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

// MARK: - Degenerate parameters (fix-algorithm-edge-cases)

extension BloomFilterTests {
    func testZeroCapacityDoesNotTrap() {
        let filter = BloomFilter(capacity: 0)
        XCTAssertGreaterThanOrEqual(filter.bitCount, 1)
        XCTAssertGreaterThanOrEqual(filter.hashFunctionCount, 1)
        filter.insert("item")
        XCTAssertTrue(filter.contains("item"))
    }

    func testNegativeCapacityCountsAsOne() {
        XCTAssertEqual(BloomFilter(capacity: -5).capacity, 1)
        XCTAssertEqual(CountingBloomFilter(capacity: -5).capacity, 1)
    }

    func testZeroRateHasFiniteBitCount() {
        let filter = BloomFilter(capacity: 100, falsePositiveRate: 0)
        XCTAssertGreaterThan(filter.falsePositiveRate, 0)
        XCTAssertGreaterThan(filter.bitCount, 1)
    }

    func testRateOfOneAndNaNAreClamped() {
        XCTAssertLessThan(BloomFilter(capacity: 100, falsePositiveRate: 1).falsePositiveRate, 1)
        XCTAssertLessThan(BloomFilter(capacity: 100, falsePositiveRate: 7).falsePositiveRate, 1)
        let nan = BloomFilter(capacity: 100, falsePositiveRate: .nan)
        XCTAssertTrue(nan.falsePositiveRate > 0 && nan.falsePositiveRate < 1)
    }

    func testCountingFilterDegenerateParameters() {
        let filter = CountingBloomFilter(capacity: 0, falsePositiveRate: 0)
        filter.insert("item")
        XCTAssertTrue(filter.contains("item"))
    }

    func testNegativeIntegers() {
        let filter = BloomFilter(capacity: 10)
        filter.insert(-1)
        filter.insert(Int.min)
        XCTAssertTrue(filter.contains(-1))
        XCTAssertTrue(filter.contains(Int.min))
        XCTAssertEqual((-1).bloomHash(), UInt64.max)
    }
}
