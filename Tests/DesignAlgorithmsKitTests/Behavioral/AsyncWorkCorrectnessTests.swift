//
//  AsyncWorkCorrectnessTests.swift
//  DesignAlgorithmsKitTests
//
//  Cancellation, failure wrapping, queue concurrency and lock release (fix-async-work-correctness)
//

import XCTest
@testable import DesignAlgorithmsKit

@available(macOS 12.0, iOS 15.0, *)
final class AsyncWorkCorrectnessTests: XCTestCase {

    private actor Flag {
        private(set) var isSet = false
        func set() { isSet = true }
    }

    private actor Log {
        private(set) var entries: [String] = []
        func append(_ entry: String) { entries.append(entry) }
    }

    private struct Boom: Error, Equatable {}

    /// Polls `condition` until it holds or `timeout` passes.
    private func waitUntil(timeout: TimeInterval = 5, _ condition: () async -> Bool) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while await !condition() {
            guard Date() < deadline else {
                XCTFail("Timed out")
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    // MARK: - JobManager

    func testCancelledPendingJobNeverRuns() async throws {
        let manager = JobManager(maxConcurrentJobs: 1)
        let ran = Flag()
        let blocker = await manager.submit(description: "blocker") {
            try await Task.sleep(nanoseconds: 100_000_000)
            return "blocker"
        }
        let queued = await manager.submit(description: "queued") {
            await ran.set()
            return "ran"
        }
        await manager.cancel(id: queued)

        try await waitUntil { await manager.getJob(id: blocker)?.status == .completed }
        try await Task.sleep(nanoseconds: 100_000_000)

        let didRun = await ran.isSet
        XCTAssertFalse(didRun)
        let job = await manager.getJob(id: queued)
        XCTAssertEqual(job?.status, .failed)
        XCTAssertEqual(job?.errorMessage, "Cancelled")
    }

    // MARK: - TaskOrchestrator

    func testFailingTaskIsWrappedAndDependentsDoNotRun() async throws {
        let orchestrator = TaskOrchestrator()
        let log = Log()
        await orchestrator.addTask(DAGTask(id: "a") { await log.append("a") })
        await orchestrator.addTask(DAGTask(id: "b", dependencies: ["a"]) { throw Boom() })
        await orchestrator.addTask(DAGTask(id: "c", dependencies: ["b"]) { await log.append("c") })

        do {
            try await orchestrator.execute()
            XCTFail("Expected taskFailure")
        } catch OrchestrationError.taskFailure(let taskId, let error) {
            XCTAssertEqual(taskId, "b")
            XCTAssertEqual(error as? Boom, Boom())
        }
        let entries = await log.entries
        XCTAssertEqual(entries, ["a"])
    }

    // MARK: - ProcessingQueue

    private struct Item: QueueItem {
        let id: Int
        var status: QueueItemStatus = .pending
        var progress: Double = 0
    }

    private actor CountingProcessor: QueueProcessor {
        private(set) var runs: [Int: Int] = [:]
        private(set) var maxConcurrency = 0
        private var current = 0

        func process(_ item: Item) async throws {
            runs[item.id, default: 0] += 1
            current += 1
            maxConcurrency = max(maxConcurrency, current)
            try await Task.sleep(nanoseconds: 2_000_000)
            current -= 1
        }
    }

    func testRapidAdditionsRunEachItemOnceWithinTheLimit() async throws {
        let processor = CountingProcessor()
        let queue = ProcessingQueue(processor: processor, maxConcurrent: 1)
        for id in 0..<10 {
            await queue.add([Item(id: id)])
        }
        await queue.resume()
        await queue.resume()

        try await waitUntil { await queue.completedItems.count == 10 }

        let runs = await processor.runs
        let maxConcurrency = await processor.maxConcurrency
        XCTAssertEqual(runs.count, 10)
        XCTAssertTrue(runs.values.allSatisfy { $0 == 1 }, "\(runs)")
        XCTAssertLessThanOrEqual(maxConcurrency, 1)
        let handles = await queue.activeTaskCount
        XCTAssertEqual(handles, 0)
    }

    func testItemsAreProcessingAsSoonAsAdded() async {
        let queue = ProcessingQueue(processor: CountingProcessor(), maxConcurrent: 2)
        await queue.add([Item(id: 1), Item(id: 2), Item(id: 3)])
        let processing = await queue.processingItems.map(\.id)
        let pending = await queue.pendingItems.map(\.id)
        XCTAssertEqual(processing, [1, 2])
        XCTAssertEqual(pending, [3])
    }

    // MARK: - ResourceCoordinator

    func testReadThenWriteOnSameKeyAndLockStateIsDropped() async throws {
        let coordinator = ResourceCoordinator()
        let read = try await coordinator.withReadLock(for: "k") { "read" }
        let write = try await coordinator.withWriteLock(for: "k") { "write" }
        XCTAssertEqual([read, write], ["read", "write"])
        let tracked = await coordinator.trackedKeyCount
        XCTAssertEqual(tracked, 0)
    }

    func testThrowingWriteReleasesItsLock() async throws {
        let coordinator = ResourceCoordinator()
        do {
            _ = try await coordinator.withWriteLock(for: "k") { () async throws -> Int in throw Boom() }
            XCTFail("Expected Boom")
        } catch is Boom {}
        let value = try await coordinator.withWriteLock(for: "k") { 42 }
        XCTAssertEqual(value, 42)
        let tracked = await coordinator.trackedKeyCount
        XCTAssertEqual(tracked, 0)
    }

    func testWritesAreExclusive() async throws {
        let coordinator = ResourceCoordinator()
        let log = Log()
        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 0..<5 {
                group.addTask {
                    try await coordinator.withWriteLock(for: "k") {
                        await log.append("start \(index)")
                        try await Task.sleep(nanoseconds: 2_000_000)
                        await log.append("end \(index)")
                    }
                }
            }
            try await group.waitForAll()
        }
        let entries = await log.entries
        for pair in stride(from: 0, to: entries.count, by: 2) {
            XCTAssertEqual(entries[pair].dropFirst(6), entries[pair + 1].dropFirst(4), "\(entries)")
        }
    }
}
