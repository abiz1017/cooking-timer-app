//
//  RecipeInputView.swift
//  CookingTimerApp
//
//  URL input and recipe fetching interface
//

import SwiftUI

/// View for inputting recipe URL and fetching recipe data
struct RecipeInputView: View {
    @ObservedObject var recipeViewModel: RecipeViewModel
    @State private var urlText: String = ""

    var onRecipeLoaded: ((Recipe) -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)

                Text("Add a Recipe")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Paste a recipe URL to automatically extract steps and timings")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)

            // URL Input
            VStack(alignment: .leading, spacing: 12) {
                Text("Recipe URL")
                    .font(.headline)

                HStack {
                    TextField("https://example.com/recipe", text: $urlText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            fetchRecipe()
                        }
                        .disabled(recipeViewModel.isLoading)

                    Button(action: fetchRecipe) {
                        if recipeViewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.title3)
                        }
                    }
                    .buttonStyle(.borderless)
                    .disabled(urlText.isEmpty || recipeViewModel.isLoading)
                    .help("Fetch recipe from URL")
                }
            }

            // Error message
            if let errorMessage = recipeViewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)

                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Retry") {
                        Task {
                            await recipeViewModel.retry()
                        }
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            // Parse result confidence
            if let parseResult = recipeViewModel.parseResult {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)

                        Text("Recipe parsed successfully")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        Text("\(Int(parseResult.confidence * 100))% confident")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Method:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(parseResult.method.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    if parseResult.confidence < 0.7 {
                        Text("⚠️ Please review and adjust step timings")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }

            // Sample URLs
            if !recipeViewModel.isLoading && recipeViewModel.recipe == nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Try a sample:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    VStack(spacing: 8) {
                        sampleURLButton(
                            "Chocolate Chip Cookies",
                            url: "https://www.allrecipes.com/recipe/10813/best-chocolate-chip-cookies/"
                        )

                        sampleURLButton(
                            "Classic Bolognese",
                            url: "https://www.seriouseats.com/the-best-slow-cooked-bolognese-sauce-recipe"
                        )

                        sampleURLButton(
                            "Roasted Vegetables",
                            url: "https://cooking.nytimes.com/recipes/1017937-roasted-vegetables"
                        )
                    }
                }
                .padding(.top)
            }

            Spacer()

            // Manual input option
            if !recipeViewModel.isLoading {
                Button(action: createManualRecipe) {
                    Label("Create Recipe Manually", systemImage: "pencil.circle")
                }
                .buttonStyle(.borderless)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: 500)
        .onChange(of: recipeViewModel.recipe) { recipe in
            if let recipe = recipe {
                onRecipeLoaded?(recipe)
            }
        }
    }

    // MARK: - Actions

    private func fetchRecipe() {
        guard !urlText.isEmpty else { return }

        Task {
            await recipeViewModel.fetchRecipe(from: urlText)
        }
    }

    private func createManualRecipe() {
        recipeViewModel.createNewRecipe()
        onRecipeLoaded?(recipeViewModel.recipe!)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func sampleURLButton(_ title: String, url: String) -> some View {
        Button(action: {
            urlText = url
            fetchRecipe()
        }) {
            HStack {
                Image(systemName: "link")
                    .font(.caption)

                Text(title)
                    .font(.caption)

                Spacer()

                Image(systemName: "arrow.right.circle")
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(.borderless)
    }
}

// MARK: - Previews

struct RecipeInputView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeInputView(recipeViewModel: RecipeViewModel())
            .frame(width: 600, height: 500)
    }
}
