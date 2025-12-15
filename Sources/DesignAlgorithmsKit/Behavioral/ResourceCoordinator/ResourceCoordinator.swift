import Foundation

/// A coordinator that manages safe concurrent access to resources identified by keys (e.g., file paths).
/// It implements a Read-Write Lock semantics where multiple readers can access a resource simultaneously,
/// but writers require exclusive access.
@available(macOS 12.0, iOS 15.0, *)
public actor ResourceCoordinator {
    
    private var locks: [String: PathLock] = [:]
    
    public init() {}
    
    /// Executes the given block with a shared (read) lock on the specified resource.
    /// Other readers can execute concurrently, but writers will block.
    public func withReadLock<T>(for key: String, operation: () async throws -> T) async throws -> T {
        return try await access(path: key, type: .read, operation: operation)
    }
    
    /// Helper to just acquire and return a token?
    /// No, closures are safer.
    
    public func access<T>(path: String, type: AccessType, operation: () async throws -> T) async throws -> T {
        let lock = getLock(for: path)
        switch type {
        case .read:
            await lock.lockRead()
            // We use standard do/defer pattern here since we are inside an async function
            defer { Task { await lock.unlockRead() } }
            return try await operation()
        case .write:
            await lock.lockWrite()
            defer { Task { await lock.unlockWrite() } }
            return try await operation()
        }
    }
    
    private func getLock(for key: String) -> PathLock {
        if let lock = locks[key] {
            return lock
        }
        let newLock = PathLock()
        locks[key] = newLock
        return newLock
    }
    
    public enum AccessType {
        case read
        case write
    }
}

/// A standard Read-Write lock implemented as an Actor.
@available(macOS 12.0, iOS 15.0, *)
actor PathLock {
    private var readers: Int = 0
    private var writers: Int = 0 // Should be 0 or 1
    private var writeWaiters: [CheckedContinuation<Void, Never>] = []
    private var readWaiters: [CheckedContinuation<Void, Never>] = []
    
    func lockRead() async {
        if writers > 0 || !writeWaiters.isEmpty {
            // Writer has priority or active
            await withCheckedContinuation { continuation in
                readWaiters.append(continuation)
            }
        } else {
            readers += 1
        }
    }
    
    func unlockRead() {
        readers -= 1
        if readers == 0 {
            // If no more readers, wake one writer if any
            if !writeWaiters.isEmpty {
                 let writer = writeWaiters.removeFirst()
                 writers = 1 // Pass ownership
                 writer.resume()
            }
        }
    }
    
    func lockWrite() async {
        if readers > 0 || writers > 0 {
            await withCheckedContinuation { continuation in
                writeWaiters.append(continuation)
            }
        } else {
            writers = 1
        }
    }
    
    func unlockWrite() {
        writers = 0
        // Prefer writers? Or strict FIFO?
        // Simple implementation: Wake one writer if present, else wake all readers.
        
        if !writeWaiters.isEmpty {
            let nextWriter = writeWaiters.removeFirst()
            writers = 1
            nextWriter.resume()
        } else {
            // Wake ALL readers
            let currentReaders = readWaiters
            readWaiters.removeAll()
            readers += currentReaders.count
            for reader in currentReaders {
                reader.resume()
            }
        }
    }
}
