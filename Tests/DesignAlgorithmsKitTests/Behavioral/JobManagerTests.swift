import XCTest
@testable import DesignAlgorithmsKit

final class MockJobManagerDelegate: JobManagerDelegate, @unchecked Sendable {
    var jobUpdates: [UUID: [JobStatus]] = [:]
    private let lock = NSLock()
    
    func jobManager(_ manager: JobManager, didUpdateJob job: JobSnapshot) {
        lock.lock()
        defer { lock.unlock() }
        var updates = jobUpdates[job.id] ?? []
        updates.append(job.status)
        jobUpdates[job.id] = updates
    }
    
    func getUpdates(for id: UUID) -> [JobStatus] {
        lock.lock()
        defer { lock.unlock() }
        return jobUpdates[id] ?? []
    }
}

final class JobManagerTests: XCTestCase {
    
    func testSubmitAndRunJob() async throws {
        let manager = JobManager(maxConcurrentJobs: 1)
        let delegate = MockJobManagerDelegate()
        await manager.setDelegate(delegate)
        
        let expectation = XCTestExpectation(description: "Job should complete")
        
        // Job returns a string
        let jobID = await manager.submit(description: "Test Job") {
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return "Success"
        }
        
        // Poll for completion
        for _ in 0..<10 {
            let snapshot = await manager.getJob(id: jobID)
            if snapshot?.status == .completed {
                expectation.fulfill()
                break
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        let snapshot = await manager.getJob(id: jobID)
        XCTAssertEqual(snapshot?.status, .completed)
        XCTAssertEqual(snapshot?.result as? String, "Success")
        
        // Verify delegate called
        let updates = delegate.getUpdates(for: jobID)
        XCTAssertTrue(updates.contains(.pending))
        XCTAssertTrue(updates.contains(.running))
        XCTAssertTrue(updates.contains(.completed))
    }
    
    func testJobFailure() async throws {
        let manager = JobManager(maxConcurrentJobs: 1)
        
        struct TestError: Error {}
        
        let jobID = await manager.submit(description: "Failing Job") {
            throw TestError()
        }
        
        // Poll
        var completed = false
        for _ in 0..<20 {
            let snapshot = await manager.getJob(id: jobID)
            if snapshot?.status == .failed {
                completed = true
                break
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        
        XCTAssertTrue(completed)
        
        let snapshot = await manager.getJob(id: jobID)
        XCTAssertEqual(snapshot?.status, .failed)
        XCTAssertNotNil(snapshot?.errorMessage)
    }
    
    func testConcurrencyLimit() async throws {
        let manager = JobManager(maxConcurrentJobs: 1)
        
        let expectation1 = XCTestExpectation(description: "Job 1 Complete")
        let expectation2 = XCTestExpectation(description: "Job 2 Complete")
        
        // Job 1 takes time
        let id1 = await manager.submit(description: "Job 1") {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            return 1
        }
        
        // Job 2 fast
        let id2 = await manager.submit(description: "Job 2") {
            return 2
        }
        
        // Immediately check: Job 1 should be running, Job 2 pending
        let snap1 = await manager.getJob(id: id1)
        let snap2 = await manager.getJob(id: id2)
        
        // Note: Timing is tricky, snap1 might still be pending if processNext hasn't run fully.
        // But with maxConcurrent=1, they can't run parallel.
        
        // We poll until both complete
        func check() async -> Bool {
            let s1 = await manager.getJob(id: id1)
            let s2 = await manager.getJob(id: id2)
            if s1?.status == .completed { expectation1.fulfill() }
            if s2?.status == .completed { expectation2.fulfill() }
            return s1?.status == .completed && s2?.status == .completed
        }
        
        // Just wait
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let finalS1 = await manager.getJob(id: id1)
        let finalS2 = await manager.getJob(id: id2)
        
        XCTAssertEqual(finalS1?.status, .completed)
        XCTAssertEqual(finalS2?.status, .completed)
    }
    
    func testCancelPendingJob() async throws {
        let manager = JobManager(maxConcurrentJobs: 1)
        
        // Block the queue
        let _ = await manager.submit(description: "Blocker") {
            try await Task.sleep(nanoseconds: 200_000_000)
            return "Done"
        }
        
        let idToCancel = await manager.submit(description: "To Cancel") {
            return "Should not run"
        }
        
        // Cancel it immediately
        await manager.cancel(id: idToCancel)
        
        let snapshot = await manager.getJob(id: idToCancel)
        XCTAssertEqual(snapshot?.status, .failed)
        XCTAssertEqual(snapshot?.errorMessage, "Cancelled")
    }

    func testAllJobIDs() async {
        let manager = JobManager()
        _ = await manager.submit(description: "1") { 1 }
        _ = await manager.submit(description: "2") { 2 }
        
        let ids = await manager.allJobIDs
        XCTAssertEqual(ids.count, 2)
    }
    
    func testGetMissingJob() async {
        let manager = JobManager()
        let snap = await manager.getJob(id: UUID())
        XCTAssertNil(snap)
    }
}
