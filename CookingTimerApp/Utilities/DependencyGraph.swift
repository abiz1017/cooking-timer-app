//
//  DependencyGraph.swift
//  CookingTimerApp
//
//  Manages dependencies between recipe steps and calculates execution order
//

import Foundation

/// Represents a directed graph of dependencies between recipe steps
struct DependencyGraph {
    /// Adjacency list: maps each step ID to the IDs of steps that depend on it
    private var adjacencyList: [UUID: Set<UUID>] = [:]

    /// Map of step IDs to their durations
    private var stepDurations: [UUID: TimeInterval] = [:]

    /// All step IDs in the graph
    private(set) var allSteps: Set<UUID> = []

    /// Create a dependency graph from recipe steps
    /// - Parameter steps: Array of recipe steps
    init(steps: [RecipeStep]) {
        for step in steps {
            allSteps.insert(step.id)
            stepDurations[step.id] = step.duration
            adjacencyList[step.id] = []
        }

        // Build the graph: for each step, add edges FROM dependencies TO the step
        for step in steps {
            for dependencyID in step.dependsOn {
                adjacencyList[dependencyID, default: []].insert(step.id)
            }
        }
    }

    /// Create an empty dependency graph
    init() {}

    // MARK: - Graph Modification

    /// Add a step to the graph
    /// - Parameters:
    ///   - stepID: Unique identifier for the step
    ///   - duration: Duration of the step
    mutating func addStep(_ stepID: UUID, duration: TimeInterval) {
        allSteps.insert(stepID)
        stepDurations[stepID] = duration
        adjacencyList[stepID] = []
    }

    /// Add a dependency relationship
    /// - Parameters:
    ///   - from: Step that must complete first
    ///   - to: Step that depends on the completion of 'from'
    mutating func addDependency(from: UUID, to: UUID) {
        adjacencyList[from, default: []].insert(to)
    }

    // MARK: - Graph Analysis

    /// Perform topological sort to find a valid execution order
    /// - Returns: Array of step IDs in execution order, or nil if cycle detected
    func topologicalSort() -> [UUID]? {
        var inDegree: [UUID: Int] = [:]
        var result: [UUID] = []

        // Calculate in-degree for each node
        for stepID in allSteps {
            inDegree[stepID] = 0
        }

        for (_, dependents) in adjacencyList {
            for dependent in dependents {
                inDegree[dependent, default: 0] += 1
            }
        }

        // Queue of nodes with no dependencies
        var queue: [UUID] = inDegree.filter { $0.value == 0 }.map { $0.key }

        while !queue.isEmpty {
            let current = queue.removeFirst()
            result.append(current)

            // For each step that depends on current
            if let dependents = adjacencyList[current] {
                for dependent in dependents {
                    inDegree[dependent]! -= 1
                    if inDegree[dependent]! == 0 {
                        queue.append(dependent)
                    }
                }
            }
        }

        // If we didn't process all nodes, there's a cycle
        if result.count != allSteps.count {
            return nil
        }

        return result
    }

    /// Detect if the graph contains any cycles
    /// - Returns: true if cycle detected, false otherwise
    func hasCycle() -> Bool {
        return topologicalSort() == nil
    }

    /// Find cycles in the graph
    /// - Returns: Array of cycles, where each cycle is an array of step IDs
    func findCycles() -> [[UUID]] {
        var cycles: [[UUID]] = []
        var visited: Set<UUID> = []
        var recursionStack: Set<UUID> = []
        var currentPath: [UUID] = []

        func dfs(_ stepID: UUID) {
            visited.insert(stepID)
            recursionStack.insert(stepID)
            currentPath.append(stepID)

            if let dependents = adjacencyList[stepID] {
                for dependent in dependents {
                    if !visited.contains(dependent) {
                        dfs(dependent)
                    } else if recursionStack.contains(dependent) {
                        // Found a cycle
                        if let cycleStart = currentPath.firstIndex(of: dependent) {
                            let cycle = Array(currentPath[cycleStart...])
                            cycles.append(cycle)
                        }
                    }
                }
            }

            recursionStack.remove(stepID)
            currentPath.removeLast()
        }

        for stepID in allSteps where !visited.contains(stepID) {
            dfs(stepID)
        }

        return cycles
    }

    /// Calculate the critical path (longest chain of dependencies)
    /// - Returns: Array of step IDs representing the critical path
    func criticalPath() -> [UUID] {
        guard let sorted = topologicalSort() else {
            return []  // Can't calculate critical path if there's a cycle
        }

        var earliestFinish: [UUID: TimeInterval] = [:]
        var predecessors: [UUID: UUID?] = [:]

        // Calculate earliest finish time for each step
        for stepID in sorted {
            let duration = stepDurations[stepID] ?? 0

            // Find the maximum earliest finish time among all dependencies
            let dependencyIDs = allSteps.filter { otherID in
                adjacencyList[otherID]?.contains(stepID) ?? false
            }

            var maxPredecessorFinish: TimeInterval = 0
            var bestPredecessor: UUID?

            for depID in dependencyIDs {
                let predFinish = earliestFinish[depID] ?? 0
                if predFinish > maxPredecessorFinish {
                    maxPredecessorFinish = predFinish
                    bestPredecessor = depID
                }
            }

            earliestFinish[stepID] = maxPredecessorFinish + duration
            predecessors[stepID] = bestPredecessor
        }

        // Find the step with the maximum earliest finish time
        guard let finalStep = earliestFinish.max(by: { $0.value < $1.value })?.key else {
            return []
        }

        // Backtrack to construct the critical path
        var path: [UUID] = []
        var current: UUID? = finalStep

        while let stepID = current {
            path.insert(stepID, at: 0)
            current = predecessors[stepID] ?? nil
        }

        return path
    }

    /// Calculate the total duration of the critical path
    /// - Returns: Total duration in seconds
    func criticalPathDuration() -> TimeInterval {
        let path = criticalPath()
        return path.reduce(0) { total, stepID in
            total + (stepDurations[stepID] ?? 0)
        }
    }

    /// Get all steps that have no dependencies (can start immediately)
    /// - Returns: Set of step IDs with no dependencies
    func getRootSteps() -> Set<UUID> {
        var roots = allSteps

        // Remove any step that has a dependency
        for (_, dependents) in adjacencyList {
            roots.subtract(dependents)
        }

        return roots
    }

    /// Get all steps that nothing depends on (final steps)
    /// - Returns: Set of step IDs that are not dependencies of any other step
    func getLeafSteps() -> Set<UUID> {
        var leaves = allSteps

        // Remove any step that has dependents
        for (stepID, dependents) in adjacencyList {
            if !dependents.isEmpty {
                leaves.remove(stepID)
            }
        }

        return leaves
    }

    /// Get all direct dependencies for a given step
    /// - Parameter stepID: Step to check
    /// - Returns: Set of step IDs that this step depends on
    func getDependencies(for stepID: UUID) -> Set<UUID> {
        var dependencies: Set<UUID> = []

        for (dependencyID, dependents) in adjacencyList {
            if dependents.contains(stepID) {
                dependencies.insert(dependencyID)
            }
        }

        return dependencies
    }

    /// Get all direct dependents for a given step (steps that depend on this one)
    /// - Parameter stepID: Step to check
    /// - Returns: Set of step IDs that depend on this step
    func getDependents(for stepID: UUID) -> Set<UUID> {
        return adjacencyList[stepID] ?? []
    }

    /// Calculate the earliest start time for each step, working backwards from a target end time
    /// - Parameter targetEndTime: The desired completion time for the entire recipe
    /// - Returns: Dictionary mapping step IDs to their calculated start times
    func calculateStartTimes(targetEndTime: Date) -> [UUID: Date] {
        guard let sorted = topologicalSort() else {
            return [:]  // Can't calculate if there's a cycle
        }

        var latestStart: [UUID: Date] = [:]

        // Start from the end time
        let criticalDuration = criticalPathDuration()
        let recipeStartTime = targetEndTime.addingTimeInterval(-criticalDuration)

        // Calculate earliest finish time for each step (forward pass)
        var earliestStart: [UUID: Date] = [:]

        for stepID in sorted {
            let duration = stepDurations[stepID] ?? 0
            let dependencies = getDependencies(for: stepID)

            if dependencies.isEmpty {
                // No dependencies - can start at recipe start time
                earliestStart[stepID] = recipeStartTime
            } else {
                // Must start after all dependencies finish
                let maxDependencyFinish = dependencies.compactMap { depID -> Date? in
                    guard let depStart = earliestStart[depID],
                          let depDuration = stepDurations[depID] else {
                        return nil
                    }
                    return depStart.addingTimeInterval(depDuration)
                }.max() ?? recipeStartTime

                earliestStart[stepID] = maxDependencyFinish
            }
        }

        // For now, return earliest start times
        // (In a more sophisticated version, we could optimize for parallel execution)
        return earliestStart
    }

    /// Validate the graph structure
    /// - Returns: Array of validation errors, empty if valid
    func validate() -> [String] {
        var errors: [String] = []

        // Check for cycles
        if hasCycle() {
            let cycles = findCycles()
            for cycle in cycles {
                errors.append("Circular dependency detected: \(cycle.map { $0.uuidString.prefix(8) }.joined(separator: " -> "))")
            }
        }

        // Check for orphaned references
        for (stepID, dependents) in adjacencyList {
            for dependent in dependents {
                if !allSteps.contains(dependent) {
                    errors.append("Step \(stepID.uuidString.prefix(8)) depends on non-existent step \(dependent.uuidString.prefix(8))")
                }
            }
        }

        return errors
    }
}
