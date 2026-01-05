//
//  RecipeParserService.swift
//  CookingTimerApp
//
//  Multi-layer recipe parsing service with robust fallbacks
//

import Foundation

/// Errors that can occur during recipe parsing
enum RecipeParseError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case noRecipeFound
    case parsingFailed(String)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL provided is not valid"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noRecipeFound:
            return "No recipe found at this URL"
        case .parsingFailed(let reason):
            return "Failed to parse recipe: \(reason)"
        case .invalidData:
            return "The recipe data is invalid or incomplete"
        }
    }
}

/// Result of a parsing attempt with confidence score
struct ParseResult {
    let recipe: Recipe
    let confidence: Double  // 0.0 to 1.0
    let method: ParseMethod

    enum ParseMethod: String {
        case schemaOrg = "Schema.org JSON-LD"
        case htmlScraping = "HTML Scraping"
        case llmExtraction = "AI Extraction"
        case manual = "Manual Input"
    }
}

/// Service for parsing recipes from URLs using multiple strategies
actor RecipeParserService {
    private let urlSession: URLSession
    private let schemaParser: SchemaOrgParser
    private let htmlScraper: HTMLScraper
    private let llmParser: LLMRecipeParser?

    init(
        urlSession: URLSession = .shared,
        enableLLMFallback: Bool = true,
        anthropicAPIKey: String? = nil
    ) {
        self.urlSession = urlSession
        self.schemaParser = SchemaOrgParser()
        self.htmlScraper = HTMLScraper()
        self.llmParser = enableLLMFallback ? LLMRecipeParser(apiKey: anthropicAPIKey) : nil
    }

    /// Parse a recipe from a URL using all available strategies
    /// - Parameter url: URL of the recipe page
    /// - Returns: ParseResult with the extracted recipe and metadata
    func parseRecipe(from url: URL) async throws -> ParseResult {
        // Step 1: Fetch HTML
        let html = try await fetchHTML(from: url)

        // Step 2: Try Schema.org JSON-LD parsing (highest confidence)
        if let result = try await trySchemaOrgParsing(html: html, sourceURL: url) {
            return result
        }

        // Step 3: Try HTML scraping (medium confidence)
        if let result = try await tryHTMLScraping(html: html, sourceURL: url) {
            return result
        }

        // Step 4: Try LLM extraction (variable confidence, but always produces something)
        if let llmParser = llmParser,
           let result = try await tryLLMExtraction(html: html, sourceURL: url, parser: llmParser) {
            return result
        }

        // If all methods fail, throw error
        throw RecipeParseError.noRecipeFound
    }

    // MARK: - Fetching

    private func fetchHTML(from url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30

        do {
            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw RecipeParseError.networkError(URLError(.badServerResponse))
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw RecipeParseError.networkError(URLError(.badServerResponse))
            }

            guard let html = String(data: data, encoding: .utf8) else {
                throw RecipeParseError.invalidData
            }

            return html
        } catch {
            throw RecipeParseError.networkError(error)
        }
    }

    // MARK: - Parsing Strategies

    private func trySchemaOrgParsing(html: String, sourceURL: URL) async throws -> ParseResult? {
        do {
            let recipe = try schemaParser.extractRecipe(from: html, sourceURL: sourceURL)

            // Calculate confidence based on data completeness
            let confidence = calculateConfidence(for: recipe)

            // Only accept if confidence is reasonable
            guard confidence > 0.5 else { return nil }

            return ParseResult(
                recipe: recipe,
                confidence: confidence,
                method: .schemaOrg
            )
        } catch {
            // Schema parsing failed, will try next method
            return nil
        }
    }

    private func tryHTMLScraping(html: String, sourceURL: URL) async throws -> ParseResult? {
        do {
            let recipe = try htmlScraper.extractRecipe(from: html, sourceURL: sourceURL)

            let confidence = calculateConfidence(for: recipe)

            // HTML scraping is less reliable, require higher threshold
            guard confidence > 0.4 else { return nil }

            return ParseResult(
                recipe: recipe,
                confidence: confidence * 0.8,  // Reduce confidence for scraping
                method: .htmlScraping
            )
        } catch {
            return nil
        }
    }

    private func tryLLMExtraction(html: String, sourceURL: URL, parser: LLMRecipeParser) async throws -> ParseResult? {
        do {
            let recipe = try await parser.extractRecipe(from: html, sourceURL: sourceURL)

            let confidence = calculateConfidence(for: recipe)

            return ParseResult(
                recipe: recipe,
                confidence: confidence * 0.9,  // LLM is usually accurate but can hallucinate
                method: .llmExtraction
            )
        } catch {
            return nil
        }
    }

    // MARK: - Confidence Calculation

    private func calculateConfidence(for recipe: Recipe) -> Double {
        var score: Double = 0.0
        var maxScore: Double = 0.0

        // Has title
        maxScore += 1.0
        if !recipe.title.isEmpty {
            score += 1.0
        }

        // Has steps
        maxScore += 2.0
        if !recipe.steps.isEmpty {
            score += 2.0
        }

        // Steps have descriptions
        maxScore += 1.0
        let stepsWithDescriptions = recipe.steps.filter { !$0.description.isEmpty }.count
        if stepsWithDescriptions == recipe.steps.count && !recipe.steps.isEmpty {
            score += 1.0
        }

        // Steps have durations
        maxScore += 2.0
        let stepsWithDurations = recipe.steps.filter { $0.duration > 0 }.count
        if stepsWithDurations == recipe.steps.count && !recipe.steps.isEmpty {
            score += 2.0
        } else if stepsWithDurations > 0 {
            score += Double(stepsWithDurations) / Double(recipe.steps.count) * 2.0
        }

        // Has total time
        maxScore += 1.0
        if recipe.totalTime > 0 {
            score += 1.0
        }

        // Has reasonable number of steps (not too few, not too many)
        maxScore += 1.0
        if (3...30).contains(recipe.steps.count) {
            score += 1.0
        } else if (1...50).contains(recipe.steps.count) {
            score += 0.5
        }

        return score / maxScore
    }
}

// MARK: - Schema.org Parser

struct SchemaOrgParser {
    /// Extract recipe from Schema.org JSON-LD structured data
    func extractRecipe(from html: String, sourceURL: URL) throws -> Recipe {
        // Find all JSON-LD script tags
        let jsonLDBlocks = extractJSONLD(from: html)

        // Try to find a Recipe schema
        for jsonString in jsonLDBlocks {
            if let recipe = try? parseRecipeJSON(jsonString, sourceURL: sourceURL) {
                return recipe
            }
        }

        throw RecipeParseError.noRecipeFound
    }

    private func extractJSONLD(from html: String) -> [String] {
        var blocks: [String] = []

        // Regex to find <script type="application/ld+json">...</script>
        let pattern = #"<script[^>]*type=["\']application/ld\+json["\'][^>]*>(.*?)</script>"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else {
            return blocks
        }

        let nsString = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            if match.numberOfRanges > 1 {
                let jsonRange = match.range(at: 1)
                if jsonRange.location != NSNotFound {
                    let jsonString = nsString.substring(with: jsonRange)
                    blocks.append(jsonString)
                }
            }
        }

        return blocks
    }

    private func parseRecipeJSON(_ jsonString: String, sourceURL: URL) throws -> Recipe {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw RecipeParseError.invalidData
        }

        let decoder = JSONDecoder()

        // Try to decode as single Recipe
        if let schemaRecipe = try? decoder.decode(SchemaRecipe.self, from: jsonData),
           schemaRecipe.type == "Recipe" || schemaRecipe.context?.contains("schema.org") == true {
            return convertToRecipe(schemaRecipe, sourceURL: sourceURL)
        }

        // Try to decode as array (some sites wrap in array)
        if let schemaArray = try? decoder.decode([SchemaRecipe].self, from: jsonData) {
            for schemaRecipe in schemaArray where schemaRecipe.type == "Recipe" {
                return convertToRecipe(schemaRecipe, sourceURL: sourceURL)
            }
        }

        throw RecipeParseError.noRecipeFound
    }

    private func convertToRecipe(_ schema: SchemaRecipe, sourceURL: URL) -> Recipe {
        var steps: [RecipeStep] = []

        // Parse recipe instructions
        if let instructions = schema.recipeInstructions {
            steps = parseInstructions(instructions)
        }

        // Parse total time if available
        let totalTime = schema.totalTime.flatMap { DurationParser.parseISO8601Duration($0) } ?? 0

        return Recipe(
            title: schema.name ?? "Untitled Recipe",
            sourceURL: sourceURL,
            steps: steps,
            totalTime: totalTime,
            servings: schema.recipeYield,
            recipeDescription: schema.description,
            imageURL: URL(string: schema.image ?? ""),
            author: schema.author?.name
        )
    }

    private func parseInstructions(_ instructions: SchemaInstructions) -> [RecipeStep] {
        var steps: [RecipeStep] = []

        switch instructions {
        case .stringArray(let strings):
            // Simple string array
            for (index, text) in strings.enumerated() {
                let duration = extractDuration(from: text)
                let stepType = inferStepType(from: text)

                steps.append(RecipeStep(
                    description: text,
                    duration: duration,
                    stepType: stepType,
                    displayOrder: index
                ))
            }

        case .string(let text):
            // Single string - split by newlines or numbers
            let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            for (index, line) in lines.enumerated() {
                let duration = extractDuration(from: line)
                let stepType = inferStepType(from: line)

                steps.append(RecipeStep(
                    description: line,
                    duration: duration,
                    stepType: stepType,
                    displayOrder: index
                ))
            }

        case .howToSteps(let howToSteps):
            // HowToStep objects (best case)
            for (index, howToStep) in howToSteps.enumerated() {
                let text = howToStep.text ?? ""
                var duration: TimeInterval = 0

                // Try to get duration from HowToStep
                if let timeString = howToStep.totalTime {
                    duration = DurationParser.parseISO8601Duration(timeString) ?? extractDuration(from: text)
                } else {
                    duration = extractDuration(from: text)
                }

                let stepType = inferStepType(from: text)

                steps.append(RecipeStep(
                    description: text,
                    duration: duration,
                    stepType: stepType,
                    displayOrder: index
                ))
            }
        }

        return steps
    }

    private func extractDuration(from text: String) -> TimeInterval {
        // Try to parse duration from text
        if let duration = DurationParser.parseNaturalDuration(text) {
            return duration
        }

        // Try to estimate from cooking terms
        if let duration = DurationParser.estimateDurationForCookingTerm(text) {
            return duration
        }

        // Default duration based on text length (rough heuristic)
        return 300  // 5 minutes default
    }

    private func inferStepType(from text: String) -> StepType {
        let lowercased = text.lowercased()

        if lowercased.contains("chop") || lowercased.contains("dice") || lowercased.contains("slice") ||
           lowercased.contains("mince") || lowercased.contains("peel") || lowercased.contains("mix") {
            return .preparation
        }

        if lowercased.contains("bake") || lowercased.contains("oven") || lowercased.contains("roast") {
            return .baking
        }

        if lowercased.contains("sauté") || lowercased.contains("fry") || lowercased.contains("boil") ||
           lowercased.contains("simmer") || lowercased.contains("cook") {
            return .cooking
        }

        if lowercased.contains("rest") || lowercased.contains("cool") || lowercased.contains("chill") ||
           lowercased.contains("marinate") {
            return .resting
        }

        if lowercased.contains("serve") || lowercased.contains("plate") || lowercased.contains("garnish") {
            return .assembly
        }

        return .preparation  // Default
    }
}

// MARK: - Schema.org Data Models

struct SchemaRecipe: Codable {
    let context: String?
    let type: String?
    let name: String?
    let description: String?
    let image: String?
    let author: SchemaAuthor?
    let recipeYield: Int?
    let totalTime: String?
    let prepTime: String?
    let cookTime: String?
    let recipeInstructions: SchemaInstructions?

    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case type = "@type"
        case name, description, image, author
        case recipeYield, totalTime, prepTime, cookTime
        case recipeInstructions
    }
}

struct SchemaAuthor: Codable {
    let name: String?
}

struct HowToStep: Codable {
    let type: String?
    let text: String?
    let totalTime: String?

    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case text, totalTime
    }
}

enum SchemaInstructions: Codable {
    case string(String)
    case stringArray([String])
    case howToSteps([HowToStep])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([String].self) {
            self = .stringArray(array)
        } else if let steps = try? container.decode([HowToStep].self) {
            self = .howToSteps(steps)
        } else {
            throw DecodingError.typeMismatch(
                SchemaInstructions.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid instruction format")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let str):
            try container.encode(str)
        case .stringArray(let arr):
            try container.encode(arr)
        case .howToSteps(let steps):
            try container.encode(steps)
        }
    }
}

// MARK: - HTML Scraper

import SwiftSoup

struct HTMLScraper {
    func extractRecipe(from html: String, sourceURL: URL) throws -> Recipe {
        do {
            let doc = try SwiftSoup.parse(html)

            // Try to extract recipe title
            let title = try extractTitle(from: doc)

            // Try to extract recipe steps
            let steps = try extractSteps(from: doc)

            guard !steps.isEmpty else {
                throw RecipeParseError.parsingFailed("No recipe steps found in HTML")
            }

            // Calculate total time from steps
            let totalTime = steps.reduce(0) { $0 + $1.duration }

            return Recipe(
                title: title,
                sourceURL: sourceURL,
                steps: steps,
                totalTime: totalTime
            )
        } catch let error as RecipeParseError {
            throw error
        } catch {
            throw RecipeParseError.parsingFailed("HTML parsing failed: \(error.localizedDescription)")
        }
    }

    private func extractTitle(from doc: Document) throws -> String {
        // Try common recipe title patterns
        let titleSelectors = [
            "h1.recipe-title",
            "h1[itemprop='name']",
            "h1.heading-content",
            ".recipe-header h1",
            "article h1",
            "h1"
        ]

        for selector in titleSelectors {
            if let element = try? doc.select(selector).first(),
               let text = try? element.text(),
               !text.isEmpty {
                return text
            }
        }

        // Fallback to page title
        if let titleElement = try? doc.select("title").first(),
           let title = try? titleElement.text() {
            return title.components(separatedBy: "|").first?.trimmingCharacters(in: .whitespaces) ?? title
        }

        return "Untitled Recipe"
    }

    private func extractSteps(from doc: Document) throws -> [RecipeStep] {
        var steps: [RecipeStep] = []

        // Try common recipe instruction patterns
        let instructionSelectors = [
            ".recipe-instructions ol li",
            ".instructions ol li",
            "[itemprop='recipeInstructions'] ol li",
            ".recipe-steps li",
            ".directions ol li",
            "ol.recipe-directions li"
        ]

        for selector in instructionSelectors {
            if let elements = try? doc.select(selector),
               !elements.isEmpty() {
                for (index, element) in elements.enumerated() {
                    if let text = try? element.text(),
                       !text.isEmpty && text.count > 10 { // Filter out very short items
                        let duration = extractDuration(from: text)
                        let stepType = inferStepType(from: text)

                        steps.append(RecipeStep(
                            description: text,
                            duration: duration,
                            stepType: stepType,
                            displayOrder: index
                        ))
                    }
                }

                if !steps.isEmpty {
                    break // Found valid steps, stop searching
                }
            }
        }

        // If no ordered list found, try paragraphs
        if steps.isEmpty {
            let paragraphSelectors = [
                ".instructions p",
                ".recipe-instructions p",
                "[itemprop='recipeInstructions'] p"
            ]

            for selector in paragraphSelectors {
                if let elements = try? doc.select(selector),
                   !elements.isEmpty() {
                    for (index, element) in elements.enumerated() {
                        if let text = try? element.text(),
                           !text.isEmpty && text.count > 20 {
                            let duration = extractDuration(from: text)
                            let stepType = inferStepType(from: text)

                            steps.append(RecipeStep(
                                description: text,
                                duration: duration,
                                stepType: stepType,
                                displayOrder: index
                            ))
                        }
                    }

                    if !steps.isEmpty {
                        break
                    }
                }
            }
        }

        return steps
    }

    private func extractDuration(from text: String) -> TimeInterval {
        // Try to parse duration from text
        if let duration = DurationParser.parseNaturalDuration(text) {
            return duration
        }

        // Try to estimate from cooking terms
        if let duration = DurationParser.estimateDurationForCookingTerm(text) {
            return duration
        }

        // Default: 5 minutes per step
        return 300
    }

    private func inferStepType(from text: String) -> StepType {
        let lowercased = text.lowercased()

        if lowercased.contains("chop") || lowercased.contains("dice") || lowercased.contains("slice") ||
           lowercased.contains("mince") || lowercased.contains("peel") || lowercased.contains("mix") {
            return .preparation
        }

        if lowercased.contains("bake") || lowercased.contains("oven") || lowercased.contains("roast") {
            return .baking
        }

        if lowercased.contains("sauté") || lowercased.contains("fry") || lowercased.contains("boil") ||
           lowercased.contains("simmer") || lowercased.contains("cook") {
            return .cooking
        }

        if lowercased.contains("rest") || lowercased.contains("cool") || lowercased.contains("chill") ||
           lowercased.contains("marinate") {
            return .resting
        }

        if lowercased.contains("serve") || lowercased.contains("plate") || lowercased.contains("garnish") {
            return .assembly
        }

        return .preparation
    }
}

// MARK: - LLM Recipe Parser (Gemini Flash)

class LLMRecipeParser {
    private let apiKey: String?
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent"

    init(apiKey: String?) {
        self.apiKey = apiKey
    }

    func extractRecipe(from html: String, sourceURL: URL) async throws -> Recipe {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            // No API key - return a sample recipe for testing
            return createSampleRecipe(sourceURL: sourceURL)
        }

        // Clean HTML - remove scripts, styles, etc.
        let cleanedHTML = cleanHTML(html)

        // Build the prompt
        let prompt = """
        Extract the recipe from this HTML content and return it as JSON with this exact structure:
        {
          "title": "recipe title",
          "steps": [
            {
              "description": "step description",
              "duration_seconds": 300,
              "step_type": "preparation|cooking|baking|resting|assembly"
            }
          ],
          "total_time_seconds": 1800
        }

        HTML content:
        \(cleanedHTML.prefix(8000))

        Important:
        - Extract ALL cooking steps in order
        - Estimate duration_seconds for each step (use common cooking times)
        - Classify each step type accurately
        - If duration is mentioned in text, use it. Otherwise estimate.
        - Return ONLY valid JSON, no markdown or explanations.
        """

        // Make API call
        let recipe = try await callGeminiAPI(prompt: prompt, sourceURL: sourceURL)
        return recipe
    }

    private func callGeminiAPI(prompt: String, sourceURL: URL) async throws -> Recipe {
        guard let url = URL(string: "\(endpoint)?key=\(apiKey ?? "")") else {
            throw RecipeParseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "maxOutputTokens": 2048
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RecipeParseError.networkError(URLError(.badServerResponse))
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw RecipeParseError.networkError(URLError(.badServerResponse))
        }

        // Parse Gemini response
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard let text = geminiResponse.candidates?.first?.content.parts.first?.text else {
            throw RecipeParseError.parsingFailed("No response from Gemini")
        }

        // Extract JSON from response (in case it's wrapped in markdown)
        let jsonString = extractJSON(from: text)

        // Parse recipe JSON
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw RecipeParseError.invalidData
        }

        let recipeJSON = try JSONDecoder().decode(GeminiRecipe.self, from: jsonData)

        // Convert to Recipe model
        let steps = recipeJSON.steps.enumerated().map { index, step in
            RecipeStep(
                description: step.description,
                duration: TimeInterval(step.duration_seconds),
                stepType: StepType(rawValue: step.step_type) ?? .preparation,
                displayOrder: index
            )
        }

        return Recipe(
            title: recipeJSON.title,
            sourceURL: sourceURL,
            steps: steps,
            totalTime: TimeInterval(recipeJSON.total_time_seconds)
        )
    }

    private func cleanHTML(_ html: String) -> String {
        var cleaned = html

        // Remove script tags
        cleaned = cleaned.replacingOccurrences(
            of: "<script[^>]*>.*?</script>",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )

        // Remove style tags
        cleaned = cleaned.replacingOccurrences(
            of: "<style[^>]*>.*?</style>",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )

        // Remove comments
        cleaned = cleaned.replacingOccurrences(
            of: "<!--.*?-->",
            with: "",
            options: [.regularExpression]
        )

        return cleaned
    }

    private func extractJSON(from text: String) -> String {
        // Try to extract JSON from markdown code blocks
        if let jsonMatch = text.range(of: "```json\\s*(.+?)```", options: .regularExpression) {
            let jsonText = text[jsonMatch]
            return String(jsonText)
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Try to find JSON object
        if let startIndex = text.firstIndex(of: "{"),
           let endIndex = text.lastIndex(of: "}") {
            return String(text[startIndex...endIndex])
        }

        return text
    }

    private func createSampleRecipe(sourceURL: URL) -> Recipe {
        // Return a sample recipe for testing when no API key is provided
        let steps = [
            RecipeStep(
                description: "Preheat oven to 375°F (190°C)",
                duration: 600,
                stepType: .baking,
                canRunInParallel: true,
                displayOrder: 0
            ),
            RecipeStep(
                description: "Chop onions, garlic, and vegetables into small pieces",
                duration: 300,
                stepType: .preparation,
                canRunInParallel: true,
                displayOrder: 1
            ),
            RecipeStep(
                description: "Heat oil in a large pan over medium heat and sauté onions until translucent",
                duration: 420,
                stepType: .cooking,
                dependsOn: [],
                displayOrder: 2
            ),
            RecipeStep(
                description: "Add garlic and cook for 1-2 minutes until fragrant",
                duration: 120,
                stepType: .cooking,
                displayOrder: 3
            ),
            RecipeStep(
                description: "Add vegetables and seasonings, cook for 10 minutes",
                duration: 600,
                stepType: .cooking,
                displayOrder: 4
            ),
            RecipeStep(
                description: "Transfer to baking dish and bake for 30 minutes",
                duration: 1800,
                stepType: .baking,
                displayOrder: 5
            ),
            RecipeStep(
                description: "Let rest for 5 minutes before serving",
                duration: 300,
                stepType: .resting,
                displayOrder: 6
            )
        ]

        return Recipe(
            title: "Sample Recipe (Demo Mode)",
            sourceURL: sourceURL,
            steps: steps,
            servings: 4,
            recipeDescription: "This is a sample recipe for testing. Set GEMINI_API_KEY environment variable to enable real parsing."
        )
    }
}

// MARK: - Gemini API Models

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String?
}

struct GeminiRecipe: Codable {
    let title: String
    let steps: [GeminiStep]
    let total_time_seconds: Int
}

struct GeminiStep: Codable {
    let description: String
    let duration_seconds: Int
    let step_type: String
}
