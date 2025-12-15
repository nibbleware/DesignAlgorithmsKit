import Foundation

/// Represents a unit of work in a dependency graph.
public struct DAGTask: Identifiable, Sendable {
    public let id: String
    public let operation: @Sendable () async throws -> Void
    public let dependencies: Set<String>
    
    public init(id: String, dependencies: Set<String> = [], operation: @escaping @Sendable () async throws -> Void) {
        self.id = id
        self.dependencies = dependencies
        self.operation = operation
    }
}

public enum OrchestrationError: Error {
    case cycleDetected
    case dependencyNotFound(taskId: String, dependencyId: String)
    case taskFailure(taskId: String, error: Error)
}

/// A Task Orchestrator that executes tasks based on a Directed Acyclic Graph (DAG).
/// It ensures that a task only runs when all its dependencies have successfully completed.
@available(macOS 12.0, iOS 15.0, *)
public actor TaskOrchestrator {
    
    private var tasks: [String: DAGTask] = [:]
    
    public init() {}
    
    /// Adds a task to the orchestrator.
    public func addTask(_ task: DAGTask) {
        tasks[task.id] = task
    }
    
    /// Validates the graph for cycles and missing dependencies.
    public func validate() throws {
        // Check for missing dependencies
        for task in tasks.values {
            for dep in task.dependencies {
                guard tasks[dep] != nil else {
                    throw OrchestrationError.dependencyNotFound(taskId: task.id, dependencyId: dep)
                }
            }
        }
        
        // Detect Cycles (DFS)
        var visited: Set<String> = []
        var recursionStack: Set<String> = []
        
        func hasCycle(_ nodeId: String) -> Bool {
            visited.insert(nodeId)
            recursionStack.insert(nodeId)
            
            if let node = tasks[nodeId] {
                for dep in node.dependencies {
                    if !visited.contains(dep) {
                        if hasCycle(dep) { return true }
                    } else if recursionStack.contains(dep) {
                        return true
                    }
                }
            }
            
            recursionStack.remove(nodeId)
            return false
        }
        
        for nodeId in tasks.keys {
            if !visited.contains(nodeId) {
                if hasCycle(nodeId) {
                    throw OrchestrationError.cycleDetected
                }
            }
        }
    }
    
    /// Executes all tasks in the graph, respecting dependencies.
    /// Runs independent tasks in parallel where possible.
    public func execute() async throws {
        try validate()
        
        // Build adjacency list for "dependents" (upstream -> [downstream])
        var dependents: [String: [String]] = [:]
        var inDegree: [String: Int] = [:]
        
        for task in tasks.values {
            inDegree[task.id] = task.dependencies.count
            for dep in task.dependencies {
                dependents[dep, default: []].append(task.id)
            }
        }
        
        // Queue of tasks ready to run (in-degree 0)
        let readyQueue: [String] = tasks.values.filter { ($0.dependencies.isEmpty) }.map { $0.id }
        
        // We use a task group to run ready tasks concurrently
        try await withThrowingTaskGroup(of: String.self) { group in
            
            // Initial batch
            for taskId in readyQueue {
                guard let task = tasks[taskId] else { continue }
                group.addTask {
                    try await task.operation()
                    return taskId
                }
            }
            
            // Loop as tasks finish
            var remainingTasks = tasks.count
            
            while remainingTasks > 0 {
                // Wait for any task to finish
                guard let finishedTaskId = try await group.next() else {
                    break 
                }
                
                remainingTasks -= 1
                
                // Unlock downstream
                 if let downstreamNodes = dependents[finishedTaskId] {
                     for downstreamId in downstreamNodes {
                         inDegree[downstreamId, default: 0] -= 1
                         if inDegree[downstreamId] == 0 {
                             // Ready!
                             if let task = tasks[downstreamId] {
                                 group.addTask {
                                     try await task.operation()
                                     return downstreamId
                                 }
                             }
                         }
                     }
                 }
            }
        }
    }
}
