import XCTest
@testable import DesignAlgorithmsKit

final class BuilderTests: XCTestCase {
    
    // MARK: - Basic Builder Pattern
    
    func testBuilderPattern() throws {
        // Given
        struct TestObject {
            let property1: String
            let property2: Int
        }
        
        class TestObjectBuilder: BaseBuilder<TestObject> {
            private var property1: String?
            private var property2: Int?
            
            func setProperty1(_ value: String) -> Self {
                self.property1 = value
                return self
            }
            
            func setProperty2(_ value: Int) -> Self {
                self.property2 = value
                return self
            }
            
            override func build() throws -> TestObject {
                guard let property1 = property1 else {
                    throw BuilderError.missingRequiredProperty("property1")
                }
                guard let property2 = property2 else {
                    throw BuilderError.missingRequiredProperty("property2")
                }
                return TestObject(property1: property1, property2: property2)
            }
        }
        
        // When
        let object = try TestObjectBuilder()
            .setProperty1("value1")
            .setProperty2(42)
            .build()
        
        // Then
        XCTAssertEqual(object.property1, "value1")
        XCTAssertEqual(object.property2, 42)
    }
    
    // MARK: - Error Handling
    
    func testBuilderMissingProperty() {
        // Given
        struct TestObject { let property: String }
        class TestObjectBuilder: BaseBuilder<TestObject> {
            override func build() throws -> TestObject {
                throw BuilderError.missingRequiredProperty("property")
            }
        }
        
        // When/Then
        XCTAssertThrowsError(try TestObjectBuilder().build()) { error in
            if case BuilderError.missingRequiredProperty(let property) = error {
                XCTAssertEqual(property, "property")
            } else {
                XCTFail("Unexpected error type")
            }
        }
    }
    
    func testValidatingBuilder() throws {
        // Given
        struct TestObject { let value: Int }
        
        class ValidatingBuilder: BaseBuilder<TestObject>, ValidatingBuilderProtocol {
            private var value: Int?
            
            func setValue(_ value: Int) -> Self {
                self.value = value
                return self
            }
            
            func validate() throws {
                guard let value = value else { throw BuilderError.missingRequiredProperty("value") }
                if value < 0 { throw BuilderError.invalidValue("value", "must be non-negative") }
            }
            
            override func build() throws -> TestObject {
                try validate()
                return TestObject(value: value!)
            }
        }
        
        // When/Then - Valid
        let object = try ValidatingBuilder().setValue(42).build()
        XCTAssertEqual(object.value, 42)
        
        // When/Then - Invalid
        XCTAssertThrowsError(try ValidatingBuilder().setValue(-1).build())
    }
    
    func testBaseBuilderNotImplemented() {
        struct TestObject { let value: String }
        class TestBuilder: BaseBuilder<TestObject> {}
        
        XCTAssertThrowsError(try TestBuilder().build()) { error in
            if case BuilderError.notImplemented = error {
                // Expected
            } else {
                XCTFail("Expected BuilderError.notImplemented, got \(error)")
            }
        }
    }
    
    func testBuilderErrorLocalizedDescription() {
        let notImplemented = BuilderError.notImplemented
        XCTAssertEqual(notImplemented.localizedDescription, "Builder build() method not implemented")
        
        let missing = BuilderError.missingRequiredProperty("testProperty")
        XCTAssertEqual(missing.localizedDescription, "Required property 'testProperty' is missing")
        
        let invalid = BuilderError.invalidValue("testProperty", "must be positive")
        XCTAssertEqual(invalid.localizedDescription, "Invalid value for 'testProperty': must be positive")
    }
    
    func testBuilderErrorEquality() {
        // Test that error cases can be matched
        let error1 = BuilderError.missingRequiredProperty("test")
        let error2 = BuilderError.missingRequiredProperty("test")
        
        if case BuilderError.missingRequiredProperty(let prop1) = error1,
           case BuilderError.missingRequiredProperty(let prop2) = error2 {
            XCTAssertEqual(prop1, prop2)
        } else {
            XCTFail("Error pattern matching failed")
        }
    }

    // MARK: - Advanced Usage
    
    func testBuilderFluentAPI() throws {
        struct ComplexObject {
            let name: String
            let age: Int
            let email: String?
            let tags: [String]
        }
        
        class ComplexObjectBuilder: BaseBuilder<ComplexObject> {
            private var name: String?
            private var age: Int?
            private var email: String?
            private var tags: [String] = []
            
            func setName(_ name: String) -> Self { self.name = name; return self }
            func setAge(_ age: Int) -> Self { self.age = age; return self }
            func setEmail(_ email: String?) -> Self { self.email = email; return self }
            func addTag(_ tag: String) -> Self { self.tags.append(tag); return self }
            
            override func build() throws -> ComplexObject {
                guard let name = name else { throw BuilderError.missingRequiredProperty("name") }
                guard let age = age else { throw BuilderError.missingRequiredProperty("age") }
                return ComplexObject(name: name, age: age, email: email, tags: tags)
            }
        }
        
        // Use fluent API
        let object = try ComplexObjectBuilder()
            .setName("John Doe")
            .setAge(30)
            .setEmail("john@example.com")
            .addTag("developer")
            .addTag("swift")
            .build()
        
        XCTAssertEqual(object.name, "John Doe")
        XCTAssertEqual(object.age, 30)
        XCTAssertEqual(object.email, "john@example.com")
        XCTAssertEqual(object.tags, ["developer", "swift"])
        
        // Partial configuration test
        // Verify order independence and state retention
        let builder = ComplexObjectBuilder()
        _ = builder.setName("Jane").setAge(25)
        
        let object1 = try builder.build()
        XCTAssertEqual(object1.name, "Jane")
        
        // Modify state
        _ = builder.setName("Jane Doe")
        let object2 = try builder.build()
        XCTAssertEqual(object2.name, "Jane Doe")
        XCTAssertEqual(object2.age, 25) // Age preserved
    }
    
    func testBuilderWithOptionalProperties() throws {
        struct OptionalObject {
            let required: String
            let optional: String?
        }
        
        class OptionalObjectBuilder: BaseBuilder<OptionalObject> {
            private var required: String?
            private var optional: String?
            
            func setRequired(_ value: String) -> Self { self.required = value; return self }
            func setOptional(_ value: String?) -> Self { self.optional = value; return self }
            
            override func build() throws -> OptionalObject {
                guard let required = required else { throw BuilderError.missingRequiredProperty("required") }
                return OptionalObject(required: required, optional: optional)
            }
        }
        
        let object1 = try OptionalObjectBuilder().setRequired("req").setOptional("opt").build()
        XCTAssertEqual(object1.optional, "opt")
        
        let object2 = try OptionalObjectBuilder().setRequired("req").setOptional(nil).build()
        XCTAssertNil(object2.optional)
    }
    
    func testBuilderMultipleInstances() throws {
        struct SimpleObject { let value: String }
        class SimpleBuilder: BaseBuilder<SimpleObject> {
            private var value: String?
            func setValue(_ value: String) -> Self { self.value = value; return self }
            override func build() throws -> SimpleObject {
                guard let value = value else { throw BuilderError.missingRequiredProperty("value") }
                return SimpleObject(value: value)
            }
        }
        
        let builder1 = SimpleBuilder()
        let builder2 = SimpleBuilder()
        
        let object1 = try builder1.setValue("value1").build()
        let object2 = try builder2.setValue("value2").build()
        
        XCTAssertEqual(object1.value, "value1")
        XCTAssertEqual(object2.value, "value2")
    }
    
    func testValidatingBuilderProtocolDefault() throws {
        struct TestObject { let value: Int }
        class DefaultValidatingBuilder: BaseBuilder<TestObject>, ValidatingBuilderProtocol {
            private var value: Int?
            func setValue(_ value: Int) -> Self { self.value = value; return self }
            override func build() throws -> TestObject {
                try validate() // Default does nothing
                guard let value = value else { throw BuilderError.missingRequiredProperty("value") }
                return TestObject(value: value)
            }
        }
        
        let object = try DefaultValidatingBuilder().setValue(42).build()
        XCTAssertEqual(object.value, 42)
    }
    
    func testValidatingBuilderProtocolDefaultImplementation() throws {
        // Direct test of default implementation
        struct TestObject { let value: String }
        class DirectValidateBuilder: BaseBuilder<TestObject>, ValidatingBuilderProtocol {
            private var value: String?
            func setValue(_ value: String) -> Self { self.value = value; return self }
            override func build() throws -> TestObject {
                try validate()
                guard let value = value else { throw BuilderError.missingRequiredProperty("value") }
                return TestObject(value: value)
            }
        }
        
        let object = try DirectValidateBuilder().setValue("test").build()
        XCTAssertEqual(object.value, "test")
    }
    
    func testValidatingBuilderWithCustomValidation() throws {
        struct User { let username: String; let age: Int }
        
        class UserBuilder: BaseBuilder<User>, ValidatingBuilderProtocol {
            private var username: String?
            private var age: Int?
            
            func setUsername(_ username: String) -> Self { self.username = username; return self }
            func setAge(_ age: Int) -> Self { self.age = age; return self }
            
            func validate() throws {
                guard let username = username else { throw BuilderError.missingRequiredProperty("username") }
                if username.count < 3 { throw BuilderError.invalidValue("username", "curr too short") }
                guard let age = age else { throw BuilderError.missingRequiredProperty("age") }
                if age < 0 || age > 150 { throw BuilderError.invalidValue("age", "invalid age") }
            }
            
            override func build() throws -> User {
                try validate()
                return User(username: username!, age: age!)
            }
        }
        
        // Happy path
        let user = try UserBuilder().setUsername("john").setAge(30).build()
        XCTAssertEqual(user.username, "john")
        
        // Invalid checks
        XCTAssertThrowsError(try UserBuilder().setUsername("a").setAge(30).build())
        XCTAssertThrowsError(try UserBuilder().setUsername("john").setAge(-1).build())
    }
    
    func testBuilderReuse() throws {
        struct Config { let host: String; let port: Int }
        class ConfigBuilder: BaseBuilder<Config> {
            private var host: String?
            private var port: Int?
            func setHost(_ host: String) -> Self { self.host = host; return self }
            func setPort(_ port: Int) -> Self { self.port = port; return self }
            override func build() throws -> Config {
                guard let h = host, let p = port else { throw BuilderError.missingRequiredProperty("config") }
                return Config(host: h, port: p)
            }
        }
        
        let builder = ConfigBuilder()
        let c1 = try builder.setHost("h1").setPort(1).build()
        XCTAssertEqual(c1.host, "h1")
        
        // Reuse
        let c2 = try builder.setPort(2).build()
        XCTAssertEqual(c2.host, "h1") // Host persisted
        XCTAssertEqual(c2.port, 2)
    }
    
    func testChainedOrderIndependence() throws {
        // Given
        struct Style {
            let color: String
            let size: Int
        }
        
        class StyleBuilder: BaseBuilder<Style> {
            private var color: String?
            private var size: Int?
            
            func setColor(_ c: String) -> Self { self.color = c; return self }
            func setSize(_ s: Int) -> Self { self.size = s; return self }
            
            override func build() throws -> Style {
                guard let c = color, let s = size else { throw BuilderError.missingRequiredProperty("style") }
                return Style(color: c, size: s)
            }
        }
        
        // When
        let s1 = try StyleBuilder().setColor("Red").setSize(10).build()
        let s2 = try StyleBuilder().setSize(10).setColor("Red").build()
        
        // Then
        XCTAssertEqual(s1.color, s2.color)
        XCTAssertEqual(s1.size, s2.size)
    }
}
