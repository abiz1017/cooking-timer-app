//
//  TimerEngineService.swift
//  CookingTimerApp
//
//  Calculates when to start each cooking step based on dependencies and serving time
//

import Foundation

/// Service responsible for timer calculations and scheduling logic
struct TimerEngineService {
    /// Buffer time to add between dependent steps (in seconds)
    var bufferTime: TimeInterval

    init(bufferTime: TimeInterval = 0) {
        self.bufferTime = bufferTime
    }

    /// Calculate start times for all recipe steps working backwards from serving time
    /// - Parameters:
    ///   - recipe: The recipe with steps to schedule
    ///   - servingTime: Desired time for the recipe to be complete
    /// - Returns: Updated recipe with calculated start times for each step
    /// - Throws: TimerCalculationError if dependencies are invalid
    func calculateStartTimes(for recipe: Recipe, servingTime: Date) throws -> Recipe {
        var updatedSteps = recipe.steps

        // Build dependency graph
        let graph = DependencyGraph(steps: updatedSteps)

        // Validate graph (check for cycles)
        let validationErrors = graph.validate()
        guard validationErrors.isEmpty else {
            throw TimerCalculationError.invalidDependencies(validationErrors.joined(separator: ", "))
        }

        // Get topological sort to ensure correct ordering
        guard let sortedStepIDs = graph.topologicalSort() else {
            throw TimerCalculationError.circularDependency
        }

        // Calculate earliest start times working forward from recipe start
        let earliestTimes = calculateEarliestStartTimes(graph: graph, sortedStepIDs: sortedStepIDs, servingTime: servingTime)

        // Calculate latest start times working backward from serving time
        let latestTimes = calculateLatestStartTimes(graph: graph, sortedStepIDs: sortedStepIDs, servingTime: servingTime)

        // For each step, use the latest possible start time (to minimize idle time)
        // But ensure we don't start before dependencies finish
        for i in 0..<updatedSteps.count {
            let stepID = updatedSteps[i].id

            // Use latest start time, but fall back to earliest if needed
            if let latestStart = latestTimes[stepID] {
                updatedSteps[i].startTime = latestStart
            } else if let earliestStart = earliestTimes[stepID] {
                updatedSteps[i].startTime = earliestStart
            }
        }

        // Create updated recipe with calculated times
        var updatedRecipe = recipe
        updatedRecipe.steps = updatedSteps

        return updatedRecipe
    }

    // MARK: - Forward Pass (Earliest Start Times)

    private func calculateEarliestStartTimes(
        graph: DependencyGraph,
        sortedStepIDs: [UUID],
        servingTime: Date
    ) -> [UUID: Date] {
        var earliestStart: [UUID: Date] = [:]
        var earliestFinish: [UUID: Date] = [:]

        // Find the critical path duration
        let criticalDuration = graph.criticalPathDuration()

        // Calculate recipe start time (serving time - critical path duration)
        let recipeStartTime = servingTime.addingTimeInterval(-criticalDuration)

        // Forward pass: calculate earliest start/finish for each step
        for stepID in sortedStepIDs {
            let dependencies = graph.getDependencies(for: stepID)
            let stepDuration = graph.allSteps.first(where: { $0 == stepID }).map { _ in
                // Get duration from step (we need to look it up)
                return 0.0  // Will be replaced below
            } ?? 0

            if dependencies.isEmpty {
                // No dependencies - can start at recipe start time
                earliestStart[stepID] = recipeStartTime
            } else {
                // Must start after all dependencies finish
                var maxDependencyFinish = recipeStartTime

                for depID in dependencies {
                    if let depFinish = earliestFinish[depID], depFinish > maxDependencyFinish {
                        maxDependencyFinish = depFinish
                    }
                }

                // Add buffer time between dependent steps
                earliestStart[stepID] = maxDependencyFinish.addingTimeInterval(bufferTime)
            }

            // Calculate finish time (we'll get actual duration from the step lookup)
            // For now, placeholder - will be filled by caller
            earliestFinish[stepID] = earliestStart[stepID]
        }

        return earliestStart
    }

    // MARK: - Backward Pass (Latest Start Times)

    private func calculateLatestStartTimes(
        graph: DependencyGraph,
        sortedStepIDs: [UUID],
        servingTime: Date
    ) -> [UUID: Date] {
        // Use the dependency graph's built-in method
        return graph.calculateStartTimes(targetEndTime: servingTime)
    }

    // MARK: - Step Grouping

    /// Group steps into parallel execution groups
    /// - Parameter recipe: Recipe with calculated start times
    /// - Returns: Array of step groups that can execute in parallel
    func groupParallelSteps(_ recipe: Recipe) -> [[RecipeStep]] {
        var groups: [[RecipeStep]] = []

        // Sort steps by start time
        let sortedSteps = recipe.steps.sorted { (step1, step2) in
            guard let time1 = step1.startTime, let time2 = step2.startTime else {
                return false
            }
            return time1 < time2
        }

        var currentGroup: [RecipeStep] = []
        var currentGroupStartTime: Date?

        for step in sortedSteps {
            guard let startTime = step.startTime else { continue }

            if let groupTime = currentGroupStartTime {
                // Check if this step starts within 1 minute of the current group
                let timeDiff = abs(startTime.timeIntervalSince(groupTime))

                if timeDiff < 60 && step.canRunInParallel {
                    // Add to current group
                    currentGroup.append(step)
                } else {
                    // Start new group
                    if !currentGroup.isEmpty {
                        groups.append(currentGroup)
                    }
                    currentGroup = [step]
                    currentGroupStartTime = startTime
                }
            } else {
                // First group
                currentGroup = [step]
                currentGroupStartTime = startTime
            }
        }

        // Add final group
        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }

        return groups
    }

    // MARK: - Timeline Generation

    /// Generate timeline information for visualization
    /// - Parameter recipe: Recipe with calculated start times
    /// - Returns: Timeline data structure
    func generateTimeline(for recipe: Recipe) -> RecipeTimeline {
        guard let firstStart = recipe.steps.compactMap({ $0.startTime }).min(),
              let lastEnd = recipe.steps.compactMap({ $0.endTime }).max() else {
            return RecipeTimeline(startTime: Date(), endTime: Date(), events: [])
        }

        var events: [TimelineEvent] = []

        for step in recipe.steps {
            guard let startTime = step.startTime else { continue }

            events.append(TimelineEvent(
                time: startTime,
                type: .stepStart,
                step: step
            ))

            if let endTime = step.endTime {
                events.append(TimelineEvent(
                    time: endTime,
                    type: .stepEnd,
                    step: step
                ))
            }
        }

        // Sort events by time
        events.sort { $0.time < $1.time }

        return RecipeTimeline(
            startTime: firstStart,
            endTime: lastEnd,
            events: events
        )
    }
}

// MARK: - Supporting Types

/// Errors that can occur during timer calculations
enum TimerCalculationError: Error, LocalizedError {
    case invalidDependencies(String)
    case circularDependency
    case noSteps
    case invalidServingTime

    var errorDescription: String? {
        switch self {
        case .invalidDependencies(let details):
            return "Invalid step dependencies: \(details)"
        case .circularDependency:
            return "Recipe contains circular dependencies between steps"
        case .noSteps:
            return "Recipe has no steps to schedule"
        case .invalidServingTime:
            return "Serving time must be in the future"
        }
    }
}

/// Timeline representation for visualization
struct RecipeTimeline {
    let startTime: Date
    let endTime: Date
    let events: [TimelineEvent]

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var formattedDuration: String {
        TimeFormatter.formatDuration(duration, style: .abbreviated)
    }
}

/// Event in the recipe timeline
struct TimelineEvent {
    let time: Date
    let type: EventType
    let step: RecipeStep

    enum EventType {
        case stepStart
        case stepEnd
    }

    var formattedTime: String {
        TimeFormatter.formatTime(time)
    }
}
