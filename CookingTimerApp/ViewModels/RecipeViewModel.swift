//
//  RecipeViewModel.swift
//  CookingTimerApp
//
//  Manages recipe fetching, parsing, and editing
//

import Foundation
import SwiftUI

/// ViewModel for recipe management
@MainActor
class RecipeViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Current recipe being worked with
    @Published var recipe: Recipe?

    /// Whether a recipe is currently being fetched
    @Published var isLoading = false

    /// Error message to display to user
    @Published var errorMessage: String?

    /// Parse result with confidence information
    @Published var parseResult: ParseResult?

    /// URL being parsed (for display)
    @Published var currentURL: URL?

    // MARK: - Dependencies

    private let parserService: RecipeParserService

    // MARK: - Initialization

    init(parserService: RecipeParserService? = nil) {
        // Create parser service with LLM fallback enabled
        // Read Gemini API key from environment variable
        let geminiAPIKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"]
        self.parserService = parserService ?? RecipeParserService(enableLLMFallback: true, anthropicAPIKey: geminiAPIKey)
    }

    // MARK: - Recipe Fetching

    /// Fetch and parse a recipe from a URL
    /// - Parameter url: URL of the recipe page
    func fetchRecipe(from url: URL) async {
        isLoading = true
        errorMessage = nil
        currentURL = url

        do {
            let result = try await parserService.parseRecipe(from: url)

            // Update on main thread
            self.parseResult = result
            self.recipe = result.recipe
            self.isLoading = false

            // Show confidence warning if low
            if result.confidence < 0.7 {
                self.errorMessage = "Recipe parsed with \(Int(result.confidence * 100))% confidence. Please review and adjust timings."
            }
        } catch let error as RecipeParseError {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        } catch {
            self.isLoading = false
            self.errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
    }

    /// Fetch recipe from URL string
    /// - Parameter urlString: String representation of URL
    func fetchRecipe(from urlString: String) async {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }

        await fetchRecipe(from: url)
    }

    // MARK: - Recipe Creation

    /// Create a new empty recipe for manual input
    func createNewRecipe(title: String = "New Recipe") {
        recipe = Recipe(
            title: title,
            steps: [],
            servings: 4
        )
        parseResult = nil
        errorMessage = nil
        currentURL = nil
    }

    // MARK: - Recipe Editing

    /// Add a new step to the recipe
    /// - Parameter step: Step to add
    func addStep(_ step: RecipeStep) {
        guard var currentRecipe = recipe else { return }

        var newStep = step
        newStep.displayOrder = currentRecipe.steps.count

        currentRecipe.steps.append(newStep)
        currentRecipe.totalTime = Recipe.calculateTotalTime(for: currentRecipe.steps)
        currentRecipe.lastModified = Date()

        recipe = currentRecipe
    }

    /// Update an existing step
    /// - Parameter step: Updated step
    func updateStep(_ step: RecipeStep) {
        guard var currentRecipe = recipe else { return }

        if let index = currentRecipe.steps.firstIndex(where: { $0.id == step.id }) {
            currentRecipe.steps[index] = step
            currentRecipe.totalTime = Recipe.calculateTotalTime(for: currentRecipe.steps)
            currentRecipe.lastModified = Date()

            recipe = currentRecipe
        }
    }

    /// Remove a step from the recipe
    /// - Parameter stepID: ID of the step to remove
    func removeStep(id stepID: UUID) {
        guard var currentRecipe = recipe else { return }

        currentRecipe.steps.removeAll { $0.id == stepID }

        // Remove this step from dependencies of other steps
        for i in 0..<currentRecipe.steps.count {
            currentRecipe.steps[i].dependsOn.removeAll { $0 == stepID }
        }

        // Recalculate display order
        for i in 0..<currentRecipe.steps.count {
            currentRecipe.steps[i].displayOrder = i
        }

        currentRecipe.totalTime = Recipe.calculateTotalTime(for: currentRecipe.steps)
        currentRecipe.lastModified = Date()

        recipe = currentRecipe
    }

    /// Reorder steps
    /// - Parameters:
    ///   - from: Source indices
    ///   - to: Destination index
    func moveSteps(from source: IndexSet, to destination: Int) {
        guard var currentRecipe = recipe else { return }

        currentRecipe.steps.move(fromOffsets: source, toOffset: destination)

        // Update display order
        for i in 0..<currentRecipe.steps.count {
            currentRecipe.steps[i].displayOrder = i
        }

        currentRecipe.lastModified = Date()
        recipe = currentRecipe
    }

    /// Update recipe metadata
    /// - Parameters:
    ///   - title: New title
    ///   - servings: Number of servings
    ///   - description: Recipe description
    func updateRecipeMetadata(title: String? = nil, servings: Int? = nil, description: String? = nil) {
        guard var currentRecipe = recipe else { return }

        if let title = title {
            currentRecipe.title = title
        }
        if let servings = servings {
            currentRecipe.servings = servings
        }
        if let description = description {
            currentRecipe.recipeDescription = description
        }

        currentRecipe.lastModified = Date()
        recipe = currentRecipe
    }

    // MARK: - Recipe Validation

    /// Validate the current recipe
    /// - Returns: Array of validation errors, empty if valid
    func validateRecipe() -> [String] {
        guard let recipe = recipe else {
            return ["No recipe loaded"]
        }

        var errors: [String] = []

        // Check for empty title
        if recipe.title.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Recipe must have a title")
        }

        // Check for no steps
        if recipe.steps.isEmpty {
            errors.append("Recipe must have at least one step")
        }

        // Check for steps with no duration
        let stepsWithoutDuration = recipe.steps.filter { $0.duration <= 0 }
        if !stepsWithoutDuration.isEmpty {
            errors.append("\(stepsWithoutDuration.count) step(s) have no duration set")
        }

        // Check for circular dependencies
        let graph = DependencyGraph(steps: recipe.steps)
        let validationErrors = graph.validate()
        errors.append(contentsOf: validationErrors)

        return errors
    }

    /// Whether the recipe is valid and ready to start timers
    var isRecipeValid: Bool {
        validateRecipe().isEmpty
    }

    // MARK: - Helper Methods

    /// Clear all data
    func clear() {
        recipe = nil
        parseResult = nil
        errorMessage = nil
        currentURL = nil
        isLoading = false
    }

    /// Retry parsing the current URL
    func retry() async {
        guard let url = currentURL else { return }
        await fetchRecipe(from: url)
    }
}
