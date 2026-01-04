//
//  Recipe.swift
//  CookingTimerApp
//
//  Represents a complete recipe with all steps and metadata
//

import Foundation

/// A complete recipe with steps, timing, and source information
struct Recipe: Identifiable, Codable, Equatable {
    /// Unique identifier for this recipe
    let id: UUID

    /// Recipe title
    var title: String

    /// Optional URL where the recipe was found
    var sourceURL: URL?

    /// All steps required to complete this recipe
    var steps: [RecipeStep]

    /// Total time from start to finish (calculated from steps)
    var totalTime: TimeInterval

    /// Number of servings this recipe makes
    var servings: Int?

    /// Optional recipe description or summary
    var recipeDescription: String?

    /// When this recipe was last modified
    var lastModified: Date

    /// Optional image URL for the recipe
    var imageURL: URL?

    /// Recipe author or source name
    var author: String?

    init(
        id: UUID = UUID(),
        title: String,
        sourceURL: URL? = nil,
        steps: [RecipeStep] = [],
        totalTime: TimeInterval = 0,
        servings: Int? = nil,
        recipeDescription: String? = nil,
        lastModified: Date = Date(),
        imageURL: URL? = nil,
        author: String? = nil
    ) {
        self.id = id
        self.title = title
        self.sourceURL = sourceURL
        self.steps = steps
        self.totalTime = totalTime == 0 ? Recipe.calculateTotalTime(for: steps) : totalTime
        self.servings = servings
        self.recipeDescription = recipeDescription
        self.lastModified = lastModified
        self.imageURL = imageURL
        self.author = author
    }

    /// Calculate total time based on steps and their dependencies
    /// This finds the critical path (longest chain of dependent steps)
    static func calculateTotalTime(for steps: [RecipeStep]) -> TimeInterval {
        guard !steps.isEmpty else { return 0 }

        // Build a map of step IDs to steps
        let stepMap = Dictionary(uniqueKeysWithValues: steps.map { ($0.id, $0) })

        // Calculate the maximum time to complete each step (including dependencies)
        var maxTimes: [UUID: TimeInterval] = [:]

        func calculateMaxTime(for stepID: UUID) -> TimeInterval {
            // Return cached value if already calculated
            if let cached = maxTimes[stepID] {
                return cached
            }

            guard let step = stepMap[stepID] else { return 0 }

            // If no dependencies, just the step's own duration
            if step.dependsOn.isEmpty {
                maxTimes[stepID] = step.duration
                return step.duration
            }

            // Find the maximum time among all dependencies
            let maxDependencyTime = step.dependsOn
                .map { calculateMaxTime(for: $0) }
                .max() ?? 0

            // Total time is max dependency time + this step's duration
            let totalTime = maxDependencyTime + step.duration
            maxTimes[stepID] = totalTime
            return totalTime
        }

        // Calculate max time for all steps and return the maximum
        return steps.map { calculateMaxTime(for: $0.id) }.max() ?? 0
    }

    /// Formatted total time as human-readable string
    var formattedTotalTime: String {
        let hours = Int(totalTime) / 3600
        let minutes = (Int(totalTime) % 3600) / 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    /// Number of steps in this recipe
    var stepCount: Int {
        steps.count
    }

    /// Steps sorted by display order
    var sortedSteps: [RecipeStep] {
        steps.sorted { $0.displayOrder < $1.displayOrder }
    }

    /// Steps grouped by type
    var stepsByType: [StepType: [RecipeStep]] {
        Dictionary(grouping: steps, by: \.stepType)
    }

    /// All step types present in this recipe
    var stepTypes: [StepType] {
        Array(Set(steps.map(\.stepType))).sorted { $0.rawValue < $1.rawValue }
    }

    /// Whether the recipe has any parallel steps
    var hasParallelSteps: Bool {
        steps.contains { $0.canRunInParallel }
    }

    /// Whether the recipe has any steps with dependencies
    var hasDependentSteps: Bool {
        steps.contains { $0.hasDependencies }
    }
}

// MARK: - Sample Data

extension Recipe {
    /// Sample recipe for testing and previews
    static var sample: Recipe {
        let step1 = RecipeStep(
            description: "Preheat oven to 375°F",
            duration: 600,
            stepType: .baking,
            canRunInParallel: true,
            displayOrder: 0
        )

        let step2 = RecipeStep(
            description: "Chop onions and garlic",
            duration: 300,
            stepType: .preparation,
            canRunInParallel: true,
            displayOrder: 1
        )

        let step3 = RecipeStep(
            description: "Sauté onions until translucent",
            duration: 420,
            stepType: .cooking,
            dependsOn: [step2.id],
            displayOrder: 2
        )

        let step4 = RecipeStep(
            description: "Add garlic and cook until fragrant",
            duration: 120,
            stepType: .cooking,
            dependsOn: [step3.id],
            displayOrder: 3
        )

        let step5 = RecipeStep(
            description: "Bake in oven",
            duration: 1800,
            stepType: .baking,
            dependsOn: [step1.id, step4.id],
            displayOrder: 4
        )

        let step6 = RecipeStep(
            description: "Let rest before serving",
            duration: 300,
            stepType: .resting,
            dependsOn: [step5.id],
            displayOrder: 5
        )

        return Recipe(
            title: "Sample Roasted Vegetables",
            sourceURL: URL(string: "https://example.com/recipe"),
            steps: [step1, step2, step3, step4, step5, step6],
            servings: 4,
            recipeDescription: "A delicious roasted vegetable dish",
            author: "Chef Sample"
        )
    }

    /// Simple recipe for quick testing
    static var simple: Recipe {
        let step1 = RecipeStep(
            description: "Boil water",
            duration: 300,
            stepType: .cooking,
            displayOrder: 0
        )

        let step2 = RecipeStep(
            description: "Add pasta and cook",
            duration: 600,
            stepType: .cooking,
            dependsOn: [step1.id],
            displayOrder: 1
        )

        return Recipe(
            title: "Simple Pasta",
            steps: [step1, step2],
            servings: 2
        )
    }
}
