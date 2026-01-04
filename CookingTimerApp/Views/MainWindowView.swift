//
//  MainWindowView.swift
//  CookingTimerApp
//
//  Main application window
//

import SwiftUI

/// Main application window view
struct MainWindowView: View {
    @StateObject private var recipeViewModel = RecipeViewModel()
    @StateObject private var timerCoordinator = TimerCoordinatorViewModel()

    @State private var currentView: AppView = .recipeInput
    @State private var servingTimeDate = Date().addingTimeInterval(3600)
    @State private var showingSettings = false

    enum AppView {
        case recipeInput
        case timerManagement
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main content
            ZStack {
                // Recipe input view
                if currentView == .recipeInput {
                    RecipeInputView(recipeViewModel: recipeViewModel) { recipe in
                        timerCoordinator.loadRecipe(recipe)
                        withAnimation {
                            currentView = .timerManagement
                        }
                    }
                    .transition(.opacity)
                }

                // Timer management view
                if currentView == .timerManagement {
                    timerManagementView
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom toolbar
            if currentView == .timerManagement {
                bottomToolbar
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingSettings) {
            settingsView
        }
    }

    // MARK: - Timer Management View

    @ViewBuilder
    private var timerManagementView: some View {
        VStack(spacing: 0) {
            // Top bar with serving time
            servingTimeBar

            Divider()

            // Timer list
            TimerListView(coordinator: timerCoordinator)
        }
    }

    // MARK: - Serving Time Bar

    @ViewBuilder
    private var servingTimeBar: some View {
        HStack(spacing: 16) {
            // Back button
            Button(action: {
                withAnimation {
                    currentView = .recipeInput
                }
            }) {
                Label("Change Recipe", systemImage: "arrow.left.circle")
            }
            .buttonStyle(.borderless)

            Divider()
                .frame(height: 24)

            // Serving time picker
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundColor(.blue)

                Text("Serve at:")
                    .font(.headline)

                DatePicker(
                    "",
                    selection: $servingTimeDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .onChange(of: servingTimeDate) { newTime in
                    timerCoordinator.updateServingTime(newTime)
                }
            }

            Spacer()

            // Recipe info
            if let recipe = timerCoordinator.scheduledRecipe {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(recipe.title)
                        .font(.headline)

                    HStack(spacing: 12) {
                        Label("\(recipe.stepCount) steps", systemImage: "list.bullet")
                            .font(.caption)

                        Label(recipe.formattedTotalTime, systemImage: "timer")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }

            // Settings button
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .help("Settings")
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Bottom Toolbar

    @ViewBuilder
    private var bottomToolbar: some View {
        HStack(spacing: 16) {
            // Progress indicator
            if !timerCoordinator.timers.isEmpty {
                HStack(spacing: 8) {
                    ProgressView(value: timerCoordinator.overallProgress)
                        .frame(width: 100)

                    Text("\(Int(timerCoordinator.overallProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Timer controls
            if timerCoordinator.isActive {
                Button(action: { timerCoordinator.pauseAll() }) {
                    Label("Pause All", systemImage: "pause.circle")
                }
                .buttonStyle(.borderless)

                Button(action: { timerCoordinator.resumeAll() }) {
                    Label("Resume All", systemImage: "play.circle")
                }
                .buttonStyle(.borderless)

                Button(role: .destructive, action: { timerCoordinator.cancelAll() }) {
                    Label("Cancel All", systemImage: "xmark.circle")
                }
                .buttonStyle(.borderless)
            } else if !timerCoordinator.timers.isEmpty {
                Button(action: { timerCoordinator.startAllTimers() }) {
                    Label("Start Timers", systemImage: "play.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if timerCoordinator.timers.contains(where: { $0.state == .completed }) {
                    Button(action: { timerCoordinator.resetAll() }) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(
            Divider(),
            alignment: .top
        )
    }

    // MARK: - Settings View

    @ViewBuilder
    private var settingsView: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title)
                .fontWeight(.bold)

            Form {
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: .constant(true))
                    Toggle("Sound", isOn: .constant(true))
                }

                Section("Timing") {
                    LabeledContent("Buffer Time") {
                        Text("30 seconds")
                    }
                }

                Section("About") {
                    LabeledContent("Version") {
                        Text("1.0.0")
                    }

                    LabeledContent("App") {
                        Text("Cooking Timer")
                    }
                }
            }
            .formStyle(.grouped)

            Spacer()

            Button("Done") {
                showingSettings = false
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 400, height: 500)
    }
}

// MARK: - Previews

struct MainWindowView_Previews: PreviewProvider {
    static var previews: some View {
        MainWindowView()
    }
}
