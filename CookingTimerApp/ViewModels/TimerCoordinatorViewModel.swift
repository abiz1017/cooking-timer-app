//
//  TimerCoordinatorViewModel.swift
//  CookingTimerApp
//
//  Orchestrates multiple cooking timers and manages their lifecycle
//

import Foundation
import SwiftUI
import Combine

/// ViewModel that coordinates all timers for a recipe
@MainActor
class TimerCoordinatorViewModel: ObservableObject {
    // MARK: - Published Properties

    /// All active timers
    @Published var timers: [CookingTimer] = []

    /// Desired serving time (when the recipe should be complete)
    @Published var servingTime: Date = Date().addingTimeInterval(3600) // Default: 1 hour from now

    /// Whether timers are currently active
    @Published var isActive = false

    /// Current recipe with calculated start times
    @Published var scheduledRecipe: Recipe?

    /// Timeline information for visualization
    @Published var timeline: RecipeTimeline?

    /// Error message
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let timerEngine: TimerEngineService
    private let notificationService: NotificationService?

    // MARK: - Private State

    private var timerCheckCancellable: AnyCancellable?
    private var autostartTimers: Set<UUID> = []

    // MARK: - Initialization

    init(
        timerEngine: TimerEngineService? = nil,
        notificationService: NotificationService? = nil
    ) {
        self.timerEngine = timerEngine ?? TimerEngineService(bufferTime: 30) // 30s buffer by default
        self.notificationService = notificationService
    }

    // MARK: - Recipe Loading

    /// Load a recipe and calculate start times
    /// - Parameter recipe: Recipe to schedule
    func loadRecipe(_ recipe: Recipe) {
        do {
            // Calculate start times based on serving time
            let scheduledRecipe = try timerEngine.calculateStartTimes(for: recipe, servingTime: servingTime)

            // Create timers for each step
            let newTimers = scheduledRecipe.steps.map { step in
                CookingTimer(step: step, state: .ready)
            }

            // Update state
            self.scheduledRecipe = scheduledRecipe
            self.timers = newTimers
            self.timeline = timerEngine.generateTimeline(for: scheduledRecipe)
            self.errorMessage = nil

        } catch let error as TimerCalculationError {
            self.errorMessage = error.localizedDescription
        } catch {
            self.errorMessage = "Failed to schedule recipe: \(error.localizedDescription)"
        }
    }

    /// Update serving time and recalculate all timers
    /// - Parameter newTime: New desired serving time
    func updateServingTime(_ newTime: Date) {
        servingTime = newTime

        // Recalculate if we have a recipe loaded
        if let recipe = scheduledRecipe {
            // Preserve original recipe (without start times)
            let originalRecipe = Recipe(
                id: recipe.id,
                title: recipe.title,
                sourceURL: recipe.sourceURL,
                steps: recipe.steps.map { step in
                    var newStep = step
                    newStep.startTime = nil
                    return newStep
                },
                totalTime: recipe.totalTime,
                servings: recipe.servings,
                recipeDescription: recipe.recipeDescription,
                imageURL: recipe.imageURL,
                author: recipe.author
            )

            loadRecipe(originalRecipe)
        }
    }

    // MARK: - Timer Control

    /// Start all timers
    func startAllTimers() {
        guard !timers.isEmpty else {
            errorMessage = "No timers to start"
            return
        }

        isActive = true
        autostartTimers = Set(timers.map { $0.id })

        // Schedule notifications for all timers
        if let notificationService = notificationService {
            Task {
                await scheduleNotifications(service: notificationService)
            }
        }

        // Start timer that checks if any timers should auto-start
        startTimerCheck()

        // Immediately start any timers that should already be running
        checkAndStartTimers()
    }

    /// Pause all running timers
    func pauseAll() {
        for timer in timers where timer.state == .running {
            timer.pause()
        }
    }

    /// Resume all paused timers
    func resumeAll() {
        for timer in timers where timer.state == .paused {
            timer.resume()
        }
    }

    /// Cancel all timers
    func cancelAll() {
        for timer in timers {
            timer.cancel()
        }

        isActive = false
        stopTimerCheck()

        // Cancel all notifications
        if let notificationService = notificationService {
            Task {
                await notificationService.cancelAllNotifications()
            }
        }
    }

    /// Reset all timers to ready state
    func resetAll() {
        for timer in timers {
            timer.reset()
        }

        isActive = false
        autostartTimers.removeAll()
        stopTimerCheck()
    }

    // MARK: - Individual Timer Control

    /// Manually start a specific timer
    /// - Parameter timerID: ID of the timer to start
    func startTimer(_ timerID: UUID) {
        guard let timer = timers.first(where: { $0.id == timerID }) else { return }

        timer.start()

        // Remove from autostart set (user manually started it)
        autostartTimers.remove(timerID)
    }

    /// Pause a specific timer
    /// - Parameter timerID: ID of the timer to pause
    func pauseTimer(_ timerID: UUID) {
        guard let timer = timers.first(where: { $0.id == timerID }) else { return }
        timer.pause()
    }

    /// Resume a specific timer
    /// - Parameter timerID: ID of the timer to resume
    func resumeTimer(_ timerID: UUID) {
        guard let timer = timers.first(where: { $0.id == timerID }) else { return }
        timer.resume()
    }

    /// Cancel a specific timer
    /// - Parameter timerID: ID of the timer to cancel
    func cancelTimer(_ timerID: UUID) {
        guard let timer = timers.first(where: { $0.id == timerID }) else { return }

        timer.cancel()
        autostartTimers.remove(timerID)
    }

    // MARK: - Timer Auto-Start

    private func startTimerCheck() {
        // Check every second if any timers should start
        timerCheckCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkAndStartTimers()
            }
    }

    private func stopTimerCheck() {
        timerCheckCancellable?.cancel()
        timerCheckCancellable = nil
    }

    private func checkAndStartTimers() {
        let currentTime = Date()

        for timer in timers {
            // Only autostart timers in the autostart set
            guard autostartTimers.contains(timer.id) else { continue }

            // Check if it's time to start this timer
            if timer.shouldStart(at: currentTime) {
                timer.start()
                autostartTimers.remove(timer.id)
            }
        }

        // Stop checking if all timers are done or no more autostarts
        if autostartTimers.isEmpty {
            let allDone = timers.allSatisfy { timer in
                timer.state == .completed || timer.state == .cancelled
            }

            if allDone {
                isActive = false
                stopTimerCheck()
            }
        }
    }

    // MARK: - Notifications

    private func scheduleNotifications(service: NotificationService) async {
        for timer in timers {
            guard let startTime = timer.scheduledStartTime else { continue }

            await service.scheduleNotification(for: timer.step, at: startTime)
        }
    }

    // MARK: - Timer Queries

    /// Get timers grouped by status
    var timersByStatus: [TimerState: [CookingTimer]] {
        Dictionary(grouping: timers, by: \.state)
    }

    /// Timers that haven't started yet
    var upcomingTimers: [CookingTimer] {
        timers.filter { $0.state == .ready }
            .sorted { ($0.scheduledStartTime ?? Date.distantFuture) < ($1.scheduledStartTime ?? Date.distantFuture) }
    }

    /// Timers currently running
    var activeTimers: [CookingTimer] {
        timers.filter { $0.state == .running }
            .sorted { ($0.scheduledStartTime ?? Date.distantPast) < ($1.scheduledStartTime ?? Date.distantPast) }
    }

    /// Timers that are paused
    var pausedTimers: [CookingTimer] {
        timers.filter { $0.state == .paused }
    }

    /// Timers that have completed
    var completedTimers: [CookingTimer] {
        timers.filter { $0.state == .completed }
            .sorted { ($0.scheduledStartTime ?? Date.distantPast) < ($1.scheduledStartTime ?? Date.distantPast) }
    }

    /// Timers that were cancelled
    var cancelledTimers: [CookingTimer] {
        timers.filter { $0.state == .cancelled }
    }

    /// Progress percentage (0.0 to 1.0)
    var overallProgress: Double {
        guard !timers.isEmpty else { return 0.0 }

        let completedCount = timers.filter { $0.state == .completed }.count
        return Double(completedCount) / Double(timers.count)
    }

    /// Next timer to start
    var nextTimer: CookingTimer? {
        upcomingTimers.first
    }

    /// Current recipe start time (earliest timer start)
    var recipeStartTime: Date? {
        timers.compactMap { $0.scheduledStartTime }.min()
    }

    /// Current recipe end time (latest timer end)
    var recipeEndTime: Date? {
        timers.compactMap { $0.scheduledEndTime }.max()
    }

    /// Time until recipe starts
    var timeUntilStart: TimeInterval? {
        guard let startTime = recipeStartTime else { return nil }
        let interval = startTime.timeIntervalSince(Date())
        return max(0, interval)
    }

    /// Whether all timers are complete
    var allTimersComplete: Bool {
        !timers.isEmpty && timers.allSatisfy { $0.state == .completed }
    }
}

// MARK: - NotificationService (Placeholder)

actor NotificationService {
    func scheduleNotification(for step: RecipeStep, at time: Date) async {
        // TODO: Implement actual notification scheduling
        print("Would schedule notification for '\(step.description)' at \(time)")
    }

    func cancelAllNotifications() async {
        // TODO: Implement notification cancellation
        print("Would cancel all notifications")
    }
}
