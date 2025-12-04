//
//  FacadeTests.swift
//  DesignAlgorithmsKitTests
//
//  Unit tests for Facade Pattern
//

import XCTest
@testable import DesignAlgorithmsKit

final class FacadeTests: XCTestCase {
    
    // MARK: - BaseFacade Tests
    
    func testBaseFacadeInitialization() {
        // Given
        let facadeID = "testFacade"
        
        // When
        let facade = BaseFacade(facadeID: facadeID)
        
        // Then
        XCTAssertEqual(facade.facadeID, facadeID)
    }
    
    // MARK: - Facade Pattern Implementation Tests
    
    func testFacadePattern() {
        // Given
        class SubsystemA {
            func operationA() -> String {
                return "A"
            }
        }
        
        class SubsystemB {
            func operationB() -> String {
                return "B"
            }
        }
        
        class SubsystemC {
            func operationC() -> String {
                return "C"
            }
        }
        
        class SystemFacade: BaseFacade {
            private let subsystemA: SubsystemA
            private let subsystemB: SubsystemB
            private let subsystemC: SubsystemC
            
            init() {
                self.subsystemA = SubsystemA()
                self.subsystemB = SubsystemB()
                self.subsystemC = SubsystemC()
                super.init(facadeID: "systemFacade")
            }
            
            func performOperation() -> String {
                let resultA = subsystemA.operationA()
                let resultB = subsystemB.operationB()
                let resultC = subsystemC.operationC()
                return "\(resultA)\(resultB)\(resultC)"
            }
        }
        
        // When
        let facade = SystemFacade()
        
        // Then
        XCTAssertEqual(facade.facadeID, "systemFacade")
        XCTAssertEqual(facade.performOperation(), "ABC")
    }
    
    func testFacadeHidesComplexity() {
        // Given
        class ComplexSubsystem {
            func step1() -> String { return "1" }
            func step2() -> String { return "2" }
            func step3() -> String { return "3" }
            func step4() -> String { return "4" }
        }
        
        class SimpleFacade: BaseFacade {
            private let subsystem: ComplexSubsystem
            
            init() {
                self.subsystem = ComplexSubsystem()
                super.init(facadeID: "simpleFacade")
            }
            
            func doEverything() -> String {
                return subsystem.step1() + subsystem.step2() + subsystem.step3() + subsystem.step4()
            }
        }
        
        // When
        let facade = SimpleFacade()
        
        // Then
        XCTAssertEqual(facade.doEverything(), "1234")
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func testAsyncFacade() async throws {
        // Given
        class AsyncSubsystem {
            func asyncOperation() async -> String {
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                return "async result"
            }
        }
        
        class AsyncFacade: BaseFacade {
            private let subsystem: AsyncSubsystem
            
            init() {
                self.subsystem = AsyncSubsystem()
                super.init(facadeID: "asyncFacade")
            }
            
            func performAsyncOperation() async -> String {
                return await subsystem.asyncOperation()
            }
        }
        
        // When
        let facade = AsyncFacade()
        let result = await facade.performAsyncOperation()
        
        // Then
        XCTAssertEqual(result, "async result")
    }
    
    func testFacadeWithMultipleSubsystems() {
        // Given
        class NetworkSubsystem {
            func fetch() -> String { return "network" }
        }
        
        class CacheSubsystem {
            func get() -> String { return "cache" }
        }
        
        class DatabaseSubsystem {
            func query() -> String { return "database" }
        }
        
        class DataFacade: BaseFacade {
            private let network: NetworkSubsystem
            private let cache: CacheSubsystem
            private let database: DatabaseSubsystem
            
            init() {
                self.network = NetworkSubsystem()
                self.cache = CacheSubsystem()
                self.database = DatabaseSubsystem()
                super.init(facadeID: "dataFacade")
            }
            
            func getData() -> String {
                // Try cache first, then network, then database
                let cached = cache.get()
                if cached != "" {
                    return cached
                }
                let networkData = network.fetch()
                if networkData != "" {
                    return networkData
                }
                return database.query()
            }
        }
        
        // When
        let facade = DataFacade()
        
        // Then
        XCTAssertEqual(facade.getData(), "cache")
    }
    
    func testFacadeProtocolConformance() {
        // Given
        class TestFacade: BaseFacade {
            override init(facadeID: String) {
                super.init(facadeID: facadeID)
            }
        }
        
        // When
        let facade: Facade = TestFacade(facadeID: "test")
        
        // Then
        XCTAssertEqual(facade.facadeID, "test")
    }
    
    func testMultipleFacades() {
        // Given
        class Facade1: BaseFacade {
            init() {
                super.init(facadeID: "facade1")
            }
            
            func operation1() -> String {
                return "facade1"
            }
        }
        
        class Facade2: BaseFacade {
            init() {
                super.init(facadeID: "facade2")
            }
            
            func operation2() -> String {
                return "facade2"
            }
        }
        
        // When
        let facade1 = Facade1()
        let facade2 = Facade2()
        
        // Then
        XCTAssertEqual(facade1.facadeID, "facade1")
        XCTAssertEqual(facade2.facadeID, "facade2")
        XCTAssertEqual(facade1.operation1(), "facade1")
        XCTAssertEqual(facade2.operation2(), "facade2")
    }
}

