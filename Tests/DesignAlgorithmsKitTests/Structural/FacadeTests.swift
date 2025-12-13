import XCTest
@testable import DesignAlgorithmsKit

final class FacadeTests: XCTestCase {
    
    // MARK: - BaseFacade Tests
    
    func testBaseFacadeInitialization() {
        let facadeID = "testFacade"
        let facade = BaseFacade(facadeID: facadeID)
        XCTAssertEqual(facade.facadeID, facadeID)
    }
    
    // MARK: - Facade Pattern Implementation
    
    func testFacadePattern() {
        class SubsystemA { func opA() -> String { "A" } }
        class SubsystemB { func opB() -> String { "B" } }
        
        class SystemFacade: BaseFacade {
            private let a = SubsystemA()
            private let b = SubsystemB()
            
            init() { super.init(facadeID: "sys") }
            
            func op() -> String { a.opA() + b.opB() }
        }
        
        let facade = SystemFacade()
        XCTAssertEqual(facade.op(), "AB")
    }
    
    func testFacadeHidesComplexity() {
        class Complex {
            func s1() -> String { "1" }
            func s2() -> String { "2" }
        }
        
        class SimpleFacade: BaseFacade {
            private let c = Complex()
            init() { super.init(facadeID: "simple") }
            func doAll() -> String { c.s1() + c.s2() }
        }
        
        XCTAssertEqual(SimpleFacade().doAll(), "12")
    }
    
    @available(macOS 10.15, iOS 13.0, *)
    func testAsyncFacade() async throws {
        class AsyncSub {
            func run() async -> String { "async" }
        }
        
        class AsyncFacade: BaseFacade {
            private let s = AsyncSub()
            init() { super.init(facadeID: "async") }
            func run() async -> String { await s.run() }
        }
        
        let res = await AsyncFacade().run()
        XCTAssertEqual(res, "async")
    }
    
    // MARK: - Nested Facades (Structural Test)
    
    func testNestedFacades() {
        // Given - Level 1 subsystems
        class Audio { func initAudio() -> String { "Audio" } }
        class Video { func initVideo() -> String { "Video" } }
        
        // Level 1 Facade
        class MediaFacade: BaseFacade {
            private let a = Audio()
            private let v = Video()
            init() { super.init(facadeID: "media") }
            func initMedia() -> String { a.initAudio() + v.initVideo() }
        }
        
        // Other subsystem
        class Physics { func initPhysics() -> String { "Physics" } }
        
        // Level 2 (Root) Facade
        class GameEngineFacade: BaseFacade {
            private let media = MediaFacade() // Nested facade
            private let physics = Physics()
            
            init() { super.init(facadeID: "engine") }
            
            func start() -> String {
                return media.initMedia() + "-" + physics.initPhysics()
            }
        }
        
        // When
        let engine = GameEngineFacade()
        
        // Then
        XCTAssertEqual(engine.start(), "AudioVideo-Physics")
    }
    
    // MARK: - Protocol Conformance
    
    func testFacadeProtocolConformance() {
        class TestFacade: BaseFacade {}
        let facade: Facade = TestFacade(facadeID: "test")
        XCTAssertEqual(facade.facadeID, "test")
    }
}
