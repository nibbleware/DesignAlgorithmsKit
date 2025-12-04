//
//  FactoryTests.swift
//  DesignAlgorithmsKitTests
//
//  Unit tests for Factory Pattern
//

import XCTest
@testable import DesignAlgorithmsKit

final class FactoryTests: XCTestCase {
    var factory: ObjectFactory!
    
    override func setUp() {
        super.setUp()
        factory = ObjectFactory.shared
        factory.clear()
    }
    
    override func tearDown() {
        factory.clear()
        super.tearDown()
    }
    
    func testRegisterFactory() {
        // Given
        let type = "test"
        
        // When
        factory.register(type: type) { config in
            return "created"
        }
        
        // Then
        XCTAssertTrue(factory.isRegistered(type: type))
    }
    
    func testCreateObject() throws {
        // Given
        factory.register(type: "test") { config in
            return "created"
        }
        
        // When
        let result = try factory.create(type: "test", configuration: [:])
        
        // Then
        XCTAssertEqual(result as? String, "created")
    }
    
    func testCreateWithConfiguration() throws {
        // Given
        factory.register(type: "test") { config in
            return config["value"] as? String ?? "default"
        }
        
        // When
        let result = try factory.create(type: "test", configuration: ["value": "custom"])
        
        // Then
        XCTAssertEqual(result as? String, "custom")
    }
    
    func testCreateNonExistentType() {
        // When/Then
        XCTAssertThrowsError(try factory.create(type: "nonexistent", configuration: [:])) { error in
            if case FactoryError.typeNotRegistered(let type) = error {
                XCTAssertEqual(type, "nonexistent")
            } else {
                XCTFail("Unexpected error type")
            }
        }
    }
    
    func testRegisterFactoryProduct() throws {
        // Given
        struct TestProduct: FactoryProduct {
            let value: String
            
            init(configuration: [String: Any]) throws {
                self.value = configuration["value"] as? String ?? "default"
            }
        }
        
        // When
        factory.register(TestProduct.self, key: "test")
        
        // Then
        let result = try factory.create(type: "test", configuration: ["value": "custom"])
        XCTAssertTrue(result is TestProduct)
        XCTAssertEqual((result as? TestProduct)?.value, "custom")
    }
}

