//
//  RecipeStep.swift
//  CookingTimerApp
//
//  Represents a single step in a recipe with timing and dependency information
//

import Foundation

/// Types of cooking steps for categorization and color coding
enum StepType: String, Codable, CaseIterable {
    case preparation  // Chopping, mixing, measuring
    case cooking      // Active cooking (sautéing, boiling, etc.)
    case baking       // Oven-based cooking
    case resting      // Cooling, marinating, rising
    case assembly     // Plating, combining components

    var displayName: String {
        rawValue.capitalized
    }

    /// Typical duration range for this step type (in seconds)
    var typicalDuration: ClosedRange<TimeInterval> {
        switch self {
        case .preparation:
            return 300...1800  // 5-30 minutes
        case .cooking:
            return 600...3600  // 10-60 minutes
        case .baking:
            return 900...5400  // 15-90 minutes
        case .resting:
            return 300...7200  // 5 minutes to 2 hours
        case .assembly:
            return 180...900   // 3-15 minutes
        }
    }

    /// Color name for UI display
    var colorName: String {
        switch self {
        case .preparation:
            return "blue"
        case .cooking:
            return "orange"
        case .baking:
            return "red"
        case .resting:
            return "purple"
        case .assembly:
            return "green"
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .preparation:
            return "scissors"
        case .cooking:
            return "flame"
        case .baking:
            return "oven"
        case .resting:
            return "clock"
        case .assembly:
            return "square.stack.3d.up"
        }
    }
}

/// A single step in a recipe with timing, dependencies, and metadata
struct RecipeStep: Identifiable, Codable, Equatable, Hashable {
    /// Unique identifier for this step
    let id: UUID

    /// Human-readable description of what to do (e.g., "Chop onions and garlic")
    var description: String

    /// How long this step takes to complete (in seconds)
    var duration: TimeInterval

    /// When to start this step (calculated by TimerEngine)
    var startTime: Date?

    /// Type of step for categorization and visualization
    var stepType: StepType

    /// Whether this step can run in parallel with other steps
    /// If false, this step must complete before dependent steps start
    var canRunInParallel: Bool

    /// IDs of steps that must complete before this step can begin
    /// Empty array means this step has no dependencies
    var dependsOn: [UUID]

    /// Optional notes or tips for this step
    var notes: String?

    /// Order index for display (not execution order, which is determined by dependencies)
    var displayOrder: Int

    init(
        id: UUID = UUID(),
        description: String,
        duration: TimeInterval,
        startTime: Date? = nil,
        stepType: StepType = .preparation,
        canRunInParallel: Bool = false,
        dependsOn: [UUID] = [],
        notes: String? = nil,
        displayOrder: Int = 0
    ) {
        self.id = id
        self.description = description
        self.duration = duration
        self.startTime = startTime
        self.stepType = stepType
        self.canRunInParallel = canRunInParallel
        self.dependsOn = dependsOn
        self.notes = notes
        self.displayOrder = displayOrder
    }

    /// End time for this step (start time + duration)
    var endTime: Date? {
        guard let start = startTime else { return nil }
        return start.addingTimeInterval(duration)
    }

    /// Whether this step has any dependencies
    var hasDependencies: Bool {
        !dependsOn.isEmpty
    }

    /// Whether this step can start at a given time
    func canStart(at time: Date) -> Bool {
        guard let start = startTime else { return false }
        return time >= start
    }

    /// Whether this step should be completed at a given time
    func shouldBeComplete(at time: Date) -> Bool {
        guard let end = endTime else { return false }
        return time >= end
    }

    /// Duration formatted as human-readable string
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h"
        } else if minutes > 0 {
            if seconds > 0 {
                return "\(minutes)m \(seconds)s"
            }
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Sample Data for Testing

extension RecipeStep {
    /// Sample recipe steps for testing and previews
    static var samples: [RecipeStep] {
        [
            RecipeStep(
                description: "Preheat oven to 375°F",
                duration: 600,  // 10 minutes
                stepType: .baking,
                canRunInParallel: true,
                displayOrder: 0
            ),
            RecipeStep(
                description: "Chop onions and garlic",
                duration: 300,  // 5 minutes
                stepType: .preparation,
                canRunInParallel: true,
                displayOrder: 1
            ),
            RecipeStep(
                description: "Sauté onions until translucent",
                duration: 420,  // 7 minutes
                stepType: .cooking,
                dependsOn: [],  // Will be populated with actual IDs
                displayOrder: 2
            ),
            RecipeStep(
                description: "Add garlic and cook until fragrant",
                duration: 120,  // 2 minutes
                stepType: .cooking,
                dependsOn: [],  // Will be populated with actual IDs
                displayOrder: 3
            ),
            RecipeStep(
                description: "Bake in oven",
                duration: 1800,  // 30 minutes
                stepType: .baking,
                dependsOn: [],  // Will be populated with actual IDs
                displayOrder: 4
            ),
            RecipeStep(
                description: "Let rest before serving",
                duration: 300,  // 5 minutes
                stepType: .resting,
                dependsOn: [],  // Will be populated with actual IDs
                displayOrder: 5
            )
        ]
    }
}
