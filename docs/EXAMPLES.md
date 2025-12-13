# Usage Examples

This document provides practical examples of using DesignAlgorithmsKit in real-world scenarios.

## Table of Contents

- [Creational Patterns](#creational-patterns)
- [Structural Patterns](#structural-patterns)
- [Behavioral Patterns](#behavioral-patterns)
- [Algorithms & Data Structures](#algorithms--data-structures)

## Creational Patterns

### Singleton: Application Configuration

```swift
import DesignAlgorithmsKit

class AppConfiguration: ThreadSafeSingleton {
    private var settings: [String: Any] = [:]
    
    private override init() {
        super.init()
        loadConfiguration()
    }
    
    override class func createShared() -> Self {
        return Self()
    }
    
    func get<T>(_ key: String, default: T) -> T {
        return settings[key] as? T ?? `default`
    }
    
    func set<T>(_ key: String, value: T) {
        settings[key] = value
    }
    
    private func loadConfiguration() {
        // Load from UserDefaults, file, etc.
        settings["apiURL"] = "https://api.example.com"
        settings["timeout"] = 30
    }
}

// Usage
let config = AppConfiguration.shared
let apiURL: String = config.get("apiURL", default: "")
config.set("debugMode", value: true)
```

### Factory: Creating UI Components

```swift
import DesignAlgorithmsKit

protocol UIComponent {
    func render()
}

class Button: UIComponent {
    let title: String
    init(title: String) { self.title = title }
    func render() { print("Button: \(title)") }
}

class TextField: UIComponent {
    let placeholder: String
    init(placeholder: String) { self.placeholder = placeholder }
    func render() { print("TextField: \(placeholder)") }
}

class UIComponentFactory: ObjectFactory {
    static func create(type: String, configuration: [String: Any]) throws -> Any {
        switch type {
        case "button":
            guard let title = configuration["title"] as? String else {
                throw FactoryError.invalidConfiguration("title required")
            }
            return Button(title: title)
        case "textField":
            guard let placeholder = configuration["placeholder"] as? String else {
                throw FactoryError.invalidConfiguration("placeholder required")
            }
            return TextField(placeholder: placeholder)
        default:
            throw FactoryError.unknownType(type)
        }
    }
}

// Usage
let button = try UIComponentFactory.create(
    type: "button",
    configuration: ["title": "Click Me"]
) as! Button
button.render()
```

### Builder: HTTP Request Construction

```swift
import DesignAlgorithmsKit
import Foundation

struct HTTPRequest {
    let url: URL
    let method: String
    let headers: [String: String]
    let body: Data?
}

class HTTPRequestBuilder: BaseBuilder<HTTPRequest> {
    private var url: URL?
    private var method: String = "GET"
    private var headers: [String: String] = [:]
    private var body: Data?
    
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
    
    func setBody(_ data: Data) -> Self {
        self.body = data
        return self
    }
    
    override func build() throws -> HTTPRequest {
        guard let url = url else {
            throw BuilderError.missingRequiredProperty("url")
        }
        return HTTPRequest(url: url, method: method, headers: headers, body: body)
    }
}

// Usage
let request = try HTTPRequestBuilder()
    .setURL(URL(string: "https://api.example.com/users")!)
    .setMethod("POST")
    .addHeader("Content-Type", value: "application/json")
    .addHeader("Authorization", value: "Bearer token123")
    .setBody("{\"name\":\"John\"}".data(using: .utf8)!)
    .build()
```

## Structural Patterns

### Adapter: Integrating Third-Party Services

```swift
import DesignAlgorithmsKit

// Your application's payment interface
protocol PaymentService {
    func charge(amount: Double, currency: String) -> Bool
}

// Third-party payment service (incompatible interface)
class StripePaymentService {
    func processPayment(amountInCents: Int, currencyCode: String) -> Bool {
        // Stripe-specific implementation
        print("Processing \(amountInCents) cents in \(currencyCode)")
        return true
    }
}

// Adapter to make Stripe compatible with your interface
class StripePaymentAdapter: Adapter {
    typealias Adaptee = StripePaymentService
    typealias Target = PaymentService
    
    private let adaptee: Adaptee
    
    init(adaptee: Adaptee) {
        self.adaptee = adaptee
    }
    
    func adapt() -> Target {
        return AdaptedStripeService(adaptee: adaptee)
    }
}

class AdaptedStripeService: PaymentService {
    private let adaptee: StripePaymentService
    
    init(adaptee: StripePaymentService) {
        self.adaptee = adaptee
    }
    
    func charge(amount: Double, currency: String) -> Bool {
        let amountInCents = Int(amount * 100)
        return adaptee.processPayment(amountInCents: amountInCents, currencyCode: currency)
    }
}

// Usage
let stripe = StripePaymentService()
let adapter = StripePaymentAdapter(adaptee: stripe)
let paymentService: PaymentService = adapter.adapt()
paymentService.charge(amount: 29.99, currency: "USD")
```

### Facade: Simplifying Complex Subsystem

```swift
import DesignAlgorithmsKit

// Complex subsystem components
class AuthenticationService {
    func authenticate(username: String, password: String) -> Bool {
        // Complex authentication logic
        return username == "admin" && password == "password"
    }
}

class AuthorizationService {
    func authorize(user: String, resource: String) -> Bool {
        // Complex authorization logic
        return true
    }
}

class AuditService {
    func log(action: String, user: String) {
        print("Audit: \(user) performed \(action)")
    }
}

// Facade to simplify access
class SecurityFacade: Facade {
    private let auth = AuthenticationService()
    private let authz = AuthorizationService()
    private let audit = AuditService()
    
    func login(username: String, password: String) -> Bool {
        let authenticated = auth.authenticate(username: username, password: password)
        if authenticated {
            audit.log(action: "login", user: username)
        }
        return authenticated
    }
    
    func accessResource(user: String, resource: String) -> Bool {
        let authorized = authz.authorize(user: user, resource: resource)
        if authorized {
            audit.log(action: "access", user: user)
        }
        return authorized
    }
}

// Usage
let security = SecurityFacade()
if security.login(username: "admin", password: "password") {
    security.accessResource(user: "admin", resource: "sensitive-data")
}
```

## Behavioral Patterns

### Strategy: Sorting Algorithms

```swift
import DesignAlgorithmsKit

struct BubbleSortStrategy: Strategy {
    func execute<T: Comparable>(_ input: [T]) -> [T] {
        var array = input
        for i in 0..<array.count {
            for j in 0..<array.count - i - 1 {
                if array[j] > array[j + 1] {
                    array.swapAt(j, j + 1)
                }
            }
        }
        return array
    }
}

struct QuickSortStrategy: Strategy {
    func execute<T: Comparable>(_ input: [T]) -> [T] {
        guard input.count > 1 else { return input }
        let pivot = input[input.count / 2]
        let less = input.filter { $0 < pivot }
        let equal = input.filter { $0 == pivot }
        let greater = input.filter { $0 > pivot }
        return execute(less) + equal + execute(greater)
    }
}

// Usage
let numbers = [64, 34, 25, 12, 22, 11, 90]

let bubbleContext = StrategyContext(strategy: BubbleSortStrategy())
let bubbleSorted = bubbleContext.execute(numbers)
print("Bubble Sort: \(bubbleSorted)")

let quickContext = StrategyContext(strategy: QuickSortStrategy())
let quickSorted = quickContext.execute(numbers)
print("Quick Sort: \(quickSorted)")
```

### Observer: Event Notification System

```swift
import DesignAlgorithmsKit

class EventPublisher: BaseObservable {
    func publishEvent(_ event: String) {
        notifyObservers(event: event)
    }
}

class EmailNotifier: Observer {
    func didReceiveNotification(from observable: any Observable, event: Any) {
        if let event = event as? String {
            print("Email: Event '\(event)' occurred")
        }
    }
}

class SMSNotifier: Observer {
    func didReceiveNotification(from observable: any Observable, event: Any) {
        if let event = event as? String {
            print("SMS: Event '\(event)' occurred")
        }
    }
}

// Usage
let publisher = EventPublisher()
let emailNotifier = EmailNotifier()
let smsNotifier = SMSNotifier()

publisher.addObserver(emailNotifier)
publisher.addObserver(smsNotifier)

publisher.publishEvent("User registered")
publisher.publishEvent("Order placed")
```

## Algorithms & Data Structures

### Merkle Tree: Data Verification

```swift
import DesignAlgorithmsKit
import Foundation

// Create data blocks
let block1 = "Transaction 1".data(using: .utf8)!
let block2 = "Transaction 2".data(using: .utf8)!
let block3 = "Transaction 3".data(using: .utf8)!
let block4 = "Transaction 4".data(using: .utf8)!

let blocks = [block1, block2, block3, block4]

// Build Merkle tree
let tree = MerkleTree.build(from: blocks)
let rootHash = tree.rootHash

print("Root hash: \(rootHash.map { String(format: "%02x", $0) }.joined())")

// Generate proof for a specific block
if let proof = tree.generateProof(for: block1) {
    // Verify proof
    let isValid = MerkleTree.verify(proof: proof, rootHash: rootHash)
    print("Proof valid: \(isValid)")
}
```

### Bloom Filter: Membership Testing

```swift
import DesignAlgorithmsKit

// Create Bloom Filter with capacity 1000 and 1% false positive rate
let filter = BloomFilter(capacity: 1000, falsePositiveRate: 0.01)

// Add items
filter.insert("apple")
filter.insert("banana")
filter.insert("cherry")

// Test membership
print(filter.contains("apple"))    // true
print(filter.contains("banana"))   // true
print(filter.contains("grape"))    // false (or possibly true due to false positive)
```

### Hash Algorithm: Data Hashing

```swift
import DesignAlgorithmsKit
import Foundation

// Hash data
let data = "Hello, World!".data(using: .utf8)!
let hash = SHA256.hash(data: data)
print("SHA-256 hash: \(hash.map { String(format: "%02x", $0) }.joined())")

// Using Data extension (New in 1.1.1)
let hexHash = data.sha256Hex
print("SHA-256 hex: \(hexHash)")

// Hash string directly
let stringHash = SHA256.hash(string: "Hello, World!")
print("String hash: \(stringHash.map { String(format: "%02x", $0) }.joined())")
```

### Counting Bloom Filter: With Removal Support

```swift
import DesignAlgorithmsKit

// Create Counting Bloom Filter
let countingFilter = CountingBloomFilter(capacity: 1000, falsePositiveRate: 0.01)

// Add items
countingFilter.insert("item1")
countingFilter.insert("item2")
countingFilter.insert("item3")

// Check membership
print(countingFilter.contains("item1"))  // true

// Remove item
countingFilter.remove("item1")
print(countingFilter.contains("item1"))  // false
```

## Complete Example: E-Commerce System

```swift
import DesignAlgorithmsKit
import Foundation

// Configuration Singleton
class ECommerceConfig: ThreadSafeSingleton {
    private override init() {
        super.init()
    }
    
    override class func createShared() -> Self {
        return Self()
    }
    
    var apiBaseURL = "https://api.ecommerce.com"
    var maxRetries = 3
}

// Product Builder
struct Product {
    let id: String
    let name: String
    let price: Double
    let description: String?
}

class ProductBuilder: BaseBuilder<Product> {
    private var id: String?
    private var name: String?
    private var price: Double?
    private var description: String?
    
    func setId(_ id: String) -> Self {
        self.id = id
        return self
    }
    
    func setName(_ name: String) -> Self {
        self.name = name
        return self
    }
    
    func setPrice(_ price: Double) -> Self {
        self.price = price
        return self
    }
    
    func setDescription(_ description: String) -> Self {
        self.description = description
        return self
    }
    
    override func build() throws -> Product {
        guard let id = id,
              let name = name,
              let price = price else {
            throw BuilderError.missingRequiredProperty("id, name, or price")
        }
        return Product(id: id, name: name, price: price, description: description)
    }
}

// Event Observer
class OrderObserver: Observer {
    func didReceiveNotification(from observable: any Observable, event: Any) {
        if let orderId = event as? String {
            print("Order \(orderId) has been placed!")
        }
    }
}

class OrderService: BaseObservable {
    func placeOrder(product: Product) {
        // Process order
        print("Placing order for \(product.name)")
        notifyObservers(event: UUID().uuidString)
    }
}

// Usage
let config = ECommerceConfig.shared
print("API URL: \(config.apiBaseURL)")

let product = try ProductBuilder()
    .setId("123")
    .setName("iPhone 15")
    .setPrice(999.99)
    .setDescription("Latest iPhone model")
    .build()

let orderService = OrderService()
let observer = OrderObserver()
orderService.addObserver(observer)

orderService.placeOrder(product: product)
```

## Best Practices

1. **Use Singletons Sparingly**: Only when you truly need a single instance
2. **Prefer Protocols**: Use protocols for better testability and flexibility
3. **Immutable Builders**: Consider making builder products immutable
4. **Error Handling**: Always handle errors from builders and factories
5. **Thread Safety**: Be aware of thread safety when using shared state
6. **Documentation**: Document your pattern usage for future maintainers

## See Also

- [Design Patterns Guide](DESIGN_PATTERNS.md)
- [Full API Documentation](https://rickhohler.github.io/DesignAlgorithmsKit/documentation/designalgorithmskit/)

