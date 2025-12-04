# Design Patterns Guide

This guide provides an overview of the design patterns implemented in DesignAlgorithmsKit, their use cases, and examples.

## Creational Patterns

### Singleton Pattern

Ensures a class has only one instance and provides global access to it.

**Implementation**: `ThreadSafeSingleton`, `ActorSingleton`

**Use Cases**:
- Configuration managers
- Logging systems
- Database connections
- Cache managers

**Example**:
```swift
class AppConfig: ThreadSafeSingleton {
    private override init() {
        super.init()
        // Initialize configuration
    }
    
    override class func createShared() -> Self {
        return Self()
    }
    
    var apiKey: String = ""
}

// Usage
AppConfig.shared.apiKey = "your-api-key"
```

### Factory Pattern

Creates objects without specifying the exact class of object that will be created.

**Implementation**: `ObjectFactory`

**Use Cases**:
- Creating objects based on configuration
- Dependency injection
- Plugin systems

**Example**:
```swift
class UserFactory: ObjectFactory {
    static func create(type: String, configuration: [String: Any]) throws -> Any {
        switch type {
        case "admin":
            return AdminUser(configuration: configuration)
        case "regular":
            return RegularUser(configuration: configuration)
        default:
            throw FactoryError.unknownType(type)
        }
    }
}
```

### Builder Pattern

Constructs complex objects step by step with a fluent API.

**Implementation**: `BaseBuilder`

**Use Cases**:
- Creating complex objects with many optional parameters
- Immutable object construction
- Configuration objects

**Example**:
```swift
class HTTPRequestBuilder: BaseBuilder<HTTPRequest> {
    private var url: URL?
    private var method: String = "GET"
    private var headers: [String: String] = [:]
    
    func setURL(_ url: URL) -> Self {
        self.url = url
        return self
    }
    
    func setMethod(_ method: String) -> Self {
        self.method = method
        return self
    }
    
    func addHeader(_ key: String, value: String) -> Self {
        self.headers[key] = value
        return self
    }
    
    override func build() throws -> HTTPRequest {
        guard let url = url else {
            throw BuilderError.missingRequiredProperty("url")
        }
        return HTTPRequest(url: url, method: method, headers: headers)
    }
}

// Usage
let request = try HTTPRequestBuilder()
    .setURL(URL(string: "https://api.example.com")!)
    .setMethod("POST")
    .addHeader("Content-Type", value: "application/json")
    .build()
```

## Structural Patterns

### Adapter Pattern

Allows objects with incompatible interfaces to work together.

**Implementation**: `Adapter` protocol

**Use Cases**:
- Integrating third-party libraries
- Legacy code integration
- Interface compatibility

**Example**:
```swift
protocol PaymentProcessor {
    func processPayment(amount: Double) -> Bool
}

class LegacyPaymentSystem {
    func pay(amount: Double) -> Bool {
        // Legacy implementation
        return true
    }
}

class LegacyPaymentAdapter: Adapter {
    typealias Adaptee = LegacyPaymentSystem
    typealias Target = PaymentProcessor
    
    private let adaptee: Adaptee
    
    init(adaptee: Adaptee) {
        self.adaptee = adaptee
    }
    
    func adapt() -> Target {
        return AdaptedPaymentProcessor(adaptee: adaptee)
    }
}

class AdaptedPaymentProcessor: PaymentProcessor {
    private let adaptee: LegacyPaymentSystem
    
    init(adaptee: LegacyPaymentSystem) {
        self.adaptee = adaptee
    }
    
    func processPayment(amount: Double) -> Bool {
        return adaptee.pay(amount: amount)
    }
}
```

### Facade Pattern

Provides a simplified interface to a complex subsystem.

**Implementation**: `Facade` protocol

**Use Cases**:
- Simplifying complex APIs
- Hiding implementation details
- Providing a unified interface

**Example**:
```swift
class MediaPlayerFacade: Facade {
    private let audioPlayer = AudioPlayer()
    private let videoPlayer = VideoPlayer()
    private let subtitleManager = SubtitleManager()
    
    func play(media: Media) {
        switch media.type {
        case .audio:
            audioPlayer.play(media.url)
        case .video:
            videoPlayer.play(media.url)
            subtitleManager.load(media.subtitleURL)
        }
    }
    
    func stop() {
        audioPlayer.stop()
        videoPlayer.stop()
        subtitleManager.hide()
    }
}
```

## Behavioral Patterns

### Strategy Pattern

Defines a family of algorithms, encapsulates each one, and makes them interchangeable.

**Implementation**: `Strategy` protocol, `StrategyContext`

**Use Cases**:
- Algorithm selection at runtime
- Different sorting strategies
- Payment processing methods

**Example**:
```swift
struct QuickSortStrategy: Strategy {
    func execute<T: Comparable>(_ input: [T]) -> [T] {
        // Quick sort implementation
        return input.sorted()
    }
}

struct MergeSortStrategy: Strategy {
    func execute<T: Comparable>(_ input: [T]) -> [T] {
        // Merge sort implementation
        return input.sorted()
    }
}

// Usage
let context = StrategyContext(strategy: QuickSortStrategy())
let sorted = context.execute([3, 1, 4, 1, 5, 9, 2, 6])
```

### Observer Pattern

Defines a one-to-many dependency between objects so that when one object changes state, all dependents are notified.

**Implementation**: `Observer` protocol, `Observable` protocol, `BaseObservable`

**Use Cases**:
- Event handling systems
- Model-View architectures
- Notification systems

**Example**:
```swift
class DataModel: BaseObservable {
    private var value: String = "" {
        didSet {
            notifyObservers(event: value)
        }
    }
    
    func updateValue(_ newValue: String) {
        value = newValue
    }
}

class ViewController: Observer {
    func didReceiveNotification(from observable: any Observable, event: Any) {
        if let value = event as? String {
            print("Value updated to: \(value)")
        }
    }
}

// Usage
let model = DataModel()
let viewController = ViewController()
model.addObserver(viewController)
model.updateValue("Hello, World!")
```

## Modern Patterns

### Registry Pattern

Provides centralized type registration and discovery.

**Implementation**: `TypeRegistry`

**Use Cases**:
- Plugin systems
- Dependency injection containers
- Type factories

**Example**:
```swift
// Register types
TypeRegistry.shared.register(UserService.self, forKey: "userService")
TypeRegistry.shared.register(ProductService.self, forKey: "productService")

// Retrieve types
if let userServiceType = TypeRegistry.shared.find(for: "userService") {
    let service = userServiceType.init()
    // Use service
}
```

## Choosing the Right Pattern

### When to Use Singleton
- You need exactly one instance of a class
- Global access is required
- Resource management (database connections, caches)

### When to Use Factory
- Object creation logic is complex
- You want to decouple object creation from usage
- You need to create objects based on runtime conditions

### When to Use Builder
- Object has many optional parameters
- You want immutable objects
- Step-by-step construction is clearer than a large initializer

### When to Use Adapter
- You need to integrate incompatible interfaces
- Working with legacy code
- Third-party library integration

### When to Use Facade
- You want to simplify a complex subsystem
- Hide implementation details
- Provide a unified interface

### When to Use Strategy
- You have multiple ways to accomplish a task
- Algorithm selection at runtime
- You want to avoid conditional statements for algorithm selection

### When to Use Observer
- You need to notify multiple objects of state changes
- Decoupling senders and receivers
- Event-driven architectures

## Best Practices

1. **Prefer Protocols**: Use protocols to define interfaces, making patterns more flexible and testable
2. **Thread Safety**: Consider thread safety for singletons and shared state
3. **Swift Concurrency**: Use actors for thread-safe singletons in async/await contexts
4. **Immutability**: Prefer immutable objects where possible
5. **Testability**: Design patterns should make code more testable, not less
6. **Documentation**: Document when and why to use each pattern

## References

- [Design Patterns: Elements of Reusable Object-Oriented Software](https://en.wikipedia.org/wiki/Design_Patterns)
- [Swift Design Patterns](https://softwarepatternslexicon.com/swift/introduction-to-design-patterns-in-swift/)
- [Apple Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)

