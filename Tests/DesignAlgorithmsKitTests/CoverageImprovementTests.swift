//
//  CoverageImprovementTests.swift
//  DesignAlgorithmsKitTests
//
//  Tests to improve code coverage for edge cases and error paths
//

import XCTest
@testable import DesignAlgorithmsKit

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class CoverageImprovementTests: XCTestCase {
    
    // MARK: - Singleton Coverage
    
    func testSingletonErrorDescription() {
        // Given
        let error = SingletonError.createSharedNotImplemented("TestClass")
        
        // When
        let description = error.localizedDescription
        
        // Then
        XCTAssertEqual(description, "Subclass 'TestClass' must implement createShared()")
    }
    
    func testThreadSafeSingletonDefaultCreateShared() {
        // Given
        class BadSingleton: ThreadSafeSingleton {
            // Intentionally not overriding createShared
        }
        
        // When/Then
        XCTAssertThrowsError(try BadSingleton.createShared()) { error in
            guard let singletonError = error as? SingletonError else {
                XCTFail("Expected SingletonError")
                return
            }
            
            if case .createSharedNotImplemented(let typeName) = singletonError {
                // The type name might be mangled or simple depending on context,
                // so we just check it contains the class name
                XCTAssertTrue(typeName.contains("BadSingleton"))
            } else {
                XCTFail("Expected createSharedNotImplemented error")
            }
        }
    }
    
    // MARK: - Merger Coverage
    
    struct SimpleItem: Mergeable {
        let id: String
        var value: Int
    }
    
    func testDefaultMergerUpsertImplementation() async throws {
        // Given - A merger that uses the default upsert implementation
        // but overrides findExisting (required)
        class DefaultUpsertMerger: DefaultMerger<SimpleItem>, @unchecked Sendable {
            var storage: [String: SimpleItem] = [:]
            
            override func findExisting(by id: String) async -> SimpleItem? {
                return storage[id]
            }
            
            // We intentionally DO NOT override upsert to test the default implementation
            // But we must support the result of upsert being saved.
            // The default upsert returns the item but doesn't persist it unless we do it?
            // Wait, DefaultMerger.upsert implementation is:
            // if let existing = await findExisting(by: item.id) {
            //     return merge(...)
            // } else {
            //     return item
            // }
            // So it does NOT persist! It just returns the result. A real implementation MUST override upsert to persist,
            // OR findExisting/merge must handle persistence (which merge doesn't).
            // This suggests DefaultMerger.upsert is purely a logic helper, not a persistence helper.
            // We can still test that logic.
        }
        
        let merger = DefaultUpsertMerger()
        let item1 = SimpleItem(id: "1", value: 10)
        
        // When - Upsert new item
        let result1 = try await merger.upsert(item1, strategy: .preferNew)
        
        // Then - Should return item1 (branch: else { return item })
        XCTAssertEqual(result1.id, "1")
        XCTAssertEqual(result1.value, 10)
        
        // Given - Existing item
        let item1v2 = SimpleItem(id: "1", value: 20)
        merger.storage["1"] = item1 // Manually persist for valid setup
        
        // When - Upsert existing item
        let result2 = try await merger.upsert(item1v2, strategy: .preferNew)
        
        // Then - Should return item1v2 (branch: if let existing...)
        XCTAssertEqual(result2.id, "1")
        XCTAssertEqual(result2.value, 20)
    }
    
    // MARK: - TaskOrchestrator Coverage
    
    func testOrchestratorCycleDetection() async {
        // Given
        let orchestrator = TaskOrchestrator()
        
        // A -> B -> A
        await orchestrator.addTask(DAGTask(id: "A", dependencies: ["B"]) { })
        await orchestrator.addTask(DAGTask(id: "B", dependencies: ["A"]) { })
        
        // When/Then
        do {
            try await orchestrator.execute()
            XCTFail("Should execute detect cycle")
        } catch let error as OrchestrationError {
            if case .cycleDetected = error {
                // Success
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testOrchestratorMissingDependency() async {
        // Given
        let orchestrator = TaskOrchestrator()
        
        // A -> Missing
        await orchestrator.addTask(DAGTask(id: "A", dependencies: ["Missing"]) { })
        
        // When/Then
        do {
            try await orchestrator.execute()
            XCTFail("Should detect missing dependency")
        } catch let error as OrchestrationError {
            if case .dependencyNotFound(let taskId, let depId) = error {
                XCTAssertEqual(taskId, "A")
                XCTAssertEqual(depId, "Missing")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    // MARK: - HashAlgorithmProtocol Coverage
    
    struct TestHashAlgo: HashAlgorithmProtocol {
        static let name = "Test"
        static func hash(data: Data) -> Data {
            return data
        }
        // Use default hash(string:)
    }
    
    func testHashAlgorithmProtocolUTF8Failure() {
        // It is extremely difficult to create a Swift String that fails UTF-8 conversion
        // because Swift Strings are guaranteed to be valid Unicode.
        // However, we can test that the method *works* for normal strings,
        // and we can try to force a failure if possible, or at least cover the happy path
        // which might NOT be covered if no one calls hash(string:) on a protocol extension.
        
        let validString = "Hello"
        let data = TestHashAlgo.hash(string: validString)
        XCTAssertEqual(data, validString.data(using: .utf8))
        
        // To truly test the guard else return hash(Data()) path, we need a string that returns nil for .data(using: .utf8).
        // This usually happens with unpaired surrogates.
        // Swift 5+ makes it hard to create such strings.
        // We can try bridging from NSString or using specific bytes.
        
        // This is a known "unpaired surrogate" that is invalid in UTF-8
        let bytes: [UInt16] = [0xD800] // High surrogate without low surrogate
        let s = String(utf16CodeUnits: bytes, count: 1)
        
        // Check if conversion fails
        if s.data(using: .utf8) == nil {
             // Fallback should happen -> hash(data: Data()) -> Empty data
             let fallbackHash = TestHashAlgo.hash(string: s)
             XCTAssertEqual(fallbackHash, Data())
        } else {
            print("Could not create invalid UTF-8 string on this platform. Skipping edge case.")
        }
    }
}
