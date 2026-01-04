//
//  TimerState.swift
//  CookingTimerApp
//
//  Represents the lifecycle state of a cooking timer
//

import Foundation

/// The current state of a cooking timer
enum TimerState: String, Codable, CaseIterable {
    /// Timer is created but not yet started (waiting for start time)
    case ready

    /// Timer is actively counting down
    case running

    /// Timer has been temporarily paused by user
    case paused

    /// Timer has finished counting down
    case completed

    /// Timer was cancelled by user before completion
    case cancelled

    /// Human-readable description of the state
    var description: String {
        switch self {
        case .ready:
            return "Ready to start"
        case .running:
            return "In progress"
        case .paused:
            return "Paused"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }

    /// Color associated with this state for UI display
    var colorName: String {
        switch self {
        case .ready:
            return "blue"
        case .running:
            return "green"
        case .paused:
            return "orange"
        case .completed:
            return "gray"
        case .cancelled:
            return "red"
        }
    }

    /// Whether the timer can be started in this state
    var canStart: Bool {
        self == .ready || self == .paused
    }

    /// Whether the timer can be paused in this state
    var canPause: Bool {
        self == .running
    }

    /// Whether the timer can be cancelled in this state
    var canCancel: Bool {
        self != .completed && self != .cancelled
    }
}
