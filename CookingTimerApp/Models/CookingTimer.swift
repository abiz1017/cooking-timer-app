//
//  CookingTimer.swift
//  CookingTimerApp
//
//  Wraps a RecipeStep with runtime timer state
//

import Foundation
import Combine

/// A timer instance that tracks the state and progress of a recipe step
@MainActor
class CookingTimer: Identifiable, ObservableObject {
    /// Unique identifier (matches the step ID)
    let id: UUID

    /// The recipe step this timer represents
    let step: RecipeStep

    /// Current state of the timer
    @Published var state: TimerState

    /// Remaining time in seconds
    @Published var remainingTime: TimeInterval

    /// Progress from 0.0 (not started) to 1.0 (completed)
    @Published var progress: Double

    /// When the timer actually started (may differ from scheduled start time)
    var actualStartTime: Date?

    /// When the timer should start (calculated by TimerEngine)
    var scheduledStartTime: Date? {
        step.startTime
    }

    /// When the timer should end (scheduled start time + duration)
    var scheduledEndTime: Date? {
        step.endTime
    }

    /// Timer publisher for countdown
    private var timerCancellable: AnyCancellable?

    init(step: RecipeStep, state: TimerState = .ready) {
        self.id = step.id
        self.step = step
        self.state = state
        self.remainingTime = step.duration
        self.progress = 0.0
    }

    /// Start the timer countdown
    func start() {
        guard state.canStart else { return }

        actualStartTime = Date()
        state = .running

        // Create a timer that fires every second
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    /// Pause the timer
    func pause() {
        guard state.canPause else { return }

        state = .paused
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    /// Resume the timer from paused state
    func resume() {
        guard state == .paused else { return }

        state = .running

        // Resume the timer
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    /// Cancel the timer
    func cancel() {
        guard state.canCancel else { return }

        state = .cancelled
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    /// Reset the timer to initial state
    func reset() {
        state = .ready
        remainingTime = step.duration
        progress = 0.0
        actualStartTime = nil
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    /// Called every second to update the timer
    private func tick() {
        guard state == .running, let startTime = actualStartTime else { return }

        let elapsed = Date().timeIntervalSince(startTime)
        remainingTime = max(0, step.duration - elapsed)
        progress = min(1.0, elapsed / step.duration)

        // Check if timer has completed
        if remainingTime <= 0 {
            complete()
        }
    }

    /// Mark the timer as completed
    private func complete() {
        state = .completed
        remainingTime = 0
        progress = 1.0
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    /// Whether it's time to start this timer based on current time
    func shouldStart(at currentTime: Date = Date()) -> Bool {
        guard state == .ready, let scheduledStart = scheduledStartTime else {
            return false
        }
        return currentTime >= scheduledStart
    }

    /// Formatted remaining time as string (e.g., "5:30" or "1:25:30")
    var formattedRemainingTime: String {
        let hours = Int(remainingTime) / 3600
        let minutes = (Int(remainingTime) % 3600) / 60
        let seconds = Int(remainingTime) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// Formatted scheduled start time as string
    var formattedStartTime: String? {
        guard let startTime = scheduledStartTime else { return nil }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }

    /// Time until this timer should start (nil if already started or no scheduled time)
    var timeUntilStart: TimeInterval? {
        guard state == .ready, let scheduledStart = scheduledStartTime else {
            return nil
        }

        let interval = scheduledStart.timeIntervalSince(Date())
        return max(0, interval)
    }

    /// Formatted time until start
    var formattedTimeUntilStart: String? {
        guard let interval = timeUntilStart else { return nil }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            if minutes > 0 {
                return "in \(hours)h \(minutes)m"
            }
            return "in \(hours)h"
        } else if minutes > 0 {
            return "in \(minutes)m"
        } else {
            return "now"
        }
    }

    /// Status message combining state and timing information
    var statusMessage: String {
        switch state {
        case .ready:
            if let timeUntil = formattedTimeUntilStart {
                return "Start \(timeUntil)"
            }
            return "Ready to start"
        case .running:
            return "In progress • \(formattedRemainingTime) remaining"
        case .paused:
            return "Paused • \(formattedRemainingTime) remaining"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }

    deinit {
        timerCancellable?.cancel()
    }
}

// MARK: - Sample Data

extension CookingTimer {
    /// Sample timer for testing
    static var sample: CookingTimer {
        let step = RecipeStep(
            description: "Sauté onions until translucent",
            duration: 420,
            stepType: .cooking
        )
        return CookingTimer(step: step)
    }

    /// Sample running timer
    static var running: CookingTimer {
        let step = RecipeStep(
            description: "Bake in oven",
            duration: 1800,
            stepType: .baking
        )
        let timer = CookingTimer(step: step, state: .running)
        timer.actualStartTime = Date().addingTimeInterval(-600) // Started 10 min ago
        timer.remainingTime = 1200 // 20 min remaining
        timer.progress = 0.33
        return timer
    }

    /// Sample completed timer
    static var completed: CookingTimer {
        let step = RecipeStep(
            description: "Chop vegetables",
            duration: 300,
            stepType: .preparation
        )
        let timer = CookingTimer(step: step, state: .completed)
        timer.remainingTime = 0
        timer.progress = 1.0
        return timer
    }
}
