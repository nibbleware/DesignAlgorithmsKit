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
    
    // MARK: - Registration and Creation
    
    func testRegisterFactory() {
        let type = "test"
        factory.register(type: type) { _ in "created" }
        XCTAssertTrue(factory.isRegistered(type: type))
    }
    
    func testCreateObject() throws {
        factory.register(type: "test") { _ in "created" }
        let result = try factory.create(type: "test", configuration: [:])
        XCTAssertEqual(result as? String, "created")
    }
    
    func testCreateWithConfiguration() throws {
        factory.register(type: "test") { config in
            return config["value"] as? String ?? "default"
        }
        let result = try factory.create(type: "test", configuration: ["value": "custom"])
        XCTAssertEqual(result as? String, "custom")
    }
    
    func testCreateNonExistentType() {
        XCTAssertThrowsError(try factory.create(type: "nonexistent", configuration: [:])) { error in
            if case FactoryError.typeNotRegistered(let type) = error {
                XCTAssertEqual(type, "nonexistent")
            } else {
                XCTFail("Unexpected error type")
            }
        }
    }
    
    // MARK: - FactoryProduct Protocol
    
    func testRegisterFactoryProduct() throws {
        struct TestProduct: FactoryProduct {
            let value: String
            init(configuration: [String: Any]) throws {
                self.value = configuration["value"] as? String ?? "default"
            }
        }
        
        factory.register(TestProduct.self, key: "test")
        let result = try factory.create(type: "test", configuration: ["value": "custom"])
        XCTAssertTrue(result is TestProduct)
        XCTAssertEqual((result as? TestProduct)?.value, "custom")
    }
    
    func testRegisterFactoryProductWithoutKey() throws {
        struct TestProduct: FactoryProduct {
            let value: String
            init(configuration: [String: Any]) throws {
                self.value = configuration["value"] as? String ?? "default"
            }
        }
        
        factory.register(TestProduct.self)
        let typeName = String(describing: TestProduct.self)
        XCTAssertTrue(factory.isRegistered(type: typeName))
        
        let result = try factory.create(type: typeName, configuration: ["value": "test"])
        XCTAssertTrue(result is TestProduct)
    }
    
    // MARK: - Errors
    
    func testFactoryErrorLocalizedDescription() {
        let notRegistered = FactoryError.typeNotRegistered("testType")
        XCTAssertEqual(notRegistered.localizedDescription, "Factory type 'testType' is not registered")
        
        let creationError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let creationFailed = FactoryError.creationFailed("testType", creationError)
        XCTAssertTrue(creationFailed.localizedDescription.contains("Failed to create 'testType'"))
        XCTAssertTrue(creationFailed.localizedDescription.contains("Test error"))
    }
    
    func testFactoryCreationFailed() {
        struct FailingProduct: FactoryProduct {
            init(configuration: [String: Any]) throws {
                throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Creation failed"])
            }
        }
        
        factory.register(FailingProduct.self, key: "failing")
        XCTAssertThrowsError(try factory.create(type: "failing", configuration: [:]))
    }
    
    func testFactoryIsRegistered() {
        XCTAssertFalse(factory.isRegistered(type: "nonexistent"))
        factory.register(type: "test") { _ in "test" }
        XCTAssertTrue(factory.isRegistered(type: "test"))
    }
    
    func testFactoryClear() {
        factory.register(type: "test1") { _ in "test1" }
        factory.register(type: "test2") { _ in "test2" }
        factory.clear()
        XCTAssertFalse(factory.isRegistered(type: "test1"))
        XCTAssertFalse(factory.isRegistered(type: "test2"))
    }
    
    // MARK: - Concurrency
    
    @MainActor
    func testFactoryRegistrationThreadSafety() {
        let expectation = expectation(description: "Registration thread safety")
        expectation.expectedFulfillmentCount = 10
        let testFactory = self.factory!
        
        for i in 0..<10 {
            DispatchQueue.global().async {
                testFactory.register(type: "type\(i)") { _ in "value\(i)" }
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
        for i in 0..<10 {
            XCTAssertTrue(factory.isRegistered(type: "type\(i)"))
        }
    }
    
    @MainActor
    func testFactoryCreationThreadSafety() {
        let expectation = expectation(description: "Creation thread safety")
        expectation.expectedFulfillmentCount = 100
        let testFactory = self.factory!
        
        // Register first
        testFactory.register(type: "concurrent") { _ in "item" }
        
        // Create concurrently
        for _ in 0..<100 {
            DispatchQueue.global().async {
                do {
                    let item = try testFactory.create(type: "concurrent", configuration: [:])
                    XCTAssertEqual(item as? String, "item")
                } catch {
                    XCTFail("Concurrent creation failed: \(error)")
                }
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
}
