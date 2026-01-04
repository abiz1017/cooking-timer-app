//
//  TimeFormatter.swift
//  CookingTimerApp
//
//  Formats TimeInterval values into human-readable strings
//

import Foundation

/// Utility for formatting time durations and dates for display
struct TimeFormatter {
    /// Format a TimeInterval as a human-readable duration string
    /// - Parameters:
    ///   - interval: Duration in seconds
    ///   - style: Formatting style to use
    /// - Returns: Formatted string (e.g., "1h 30m", "45 seconds")
    static func formatDuration(_ interval: TimeInterval, style: DurationStyle = .abbreviated) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60

        switch style {
        case .abbreviated:
            return formatAbbreviated(hours: hours, minutes: minutes, seconds: seconds)
        case .full:
            return formatFull(hours: hours, minutes: minutes, seconds: seconds)
        case .compact:
            return formatCompact(hours: hours, minutes: minutes, seconds: seconds)
        case .timer:
            return formatTimer(hours: hours, minutes: minutes, seconds: seconds)
        }
    }

    /// Format style options for duration display
    enum DurationStyle {
        case abbreviated  // "1h 30m"
        case full         // "1 hour 30 minutes"
        case compact      // "1:30:00"
        case timer        // "1:30" or "1:30:00" (like a countdown timer)
    }

    // MARK: - Private Formatting Methods

    private static func formatAbbreviated(hours: Int, minutes: Int, seconds: Int) -> String {
        var parts: [String] = []

        if hours > 0 {
            parts.append("\(hours)h")
        }
        if minutes > 0 {
            parts.append("\(minutes)m")
        }
        if seconds > 0 && hours == 0 {  // Only show seconds if less than an hour
            parts.append("\(seconds)s")
        }

        if parts.isEmpty {
            return "0s"
        }

        return parts.joined(separator: " ")
    }

    private static func formatFull(hours: Int, minutes: Int, seconds: Int) -> String {
        var parts: [String] = []

        if hours > 0 {
            parts.append("\(hours) \(hours == 1 ? "hour" : "hours")")
        }
        if minutes > 0 {
            parts.append("\(minutes) \(minutes == 1 ? "minute" : "minutes")")
        }
        if seconds > 0 && hours == 0 {
            parts.append("\(seconds) \(seconds == 1 ? "second" : "seconds")")
        }

        if parts.isEmpty {
            return "0 seconds"
        }

        return parts.joined(separator: " ")
    }

    private static func formatCompact(hours: Int, minutes: Int, seconds: Int) -> String {
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    private static func formatTimer(hours: Int, minutes: Int, seconds: Int) -> String {
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    // MARK: - Date/Time Formatting

    /// Format a date as a time string (e.g., "2:30 PM")
    /// - Parameter date: Date to format
    /// - Returns: Formatted time string
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    /// Format a date as a date and time string (e.g., "Jan 4, 2:30 PM")
    /// - Parameter date: Date to format
    /// - Returns: Formatted date and time string
    static func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Format time interval until a future date
    /// - Parameter date: Future date
    /// - Returns: Human-readable string (e.g., "in 15m", "in 2h 30m")
    static func formatTimeUntil(_ date: Date) -> String {
        let interval = date.timeIntervalSince(Date())

        if interval <= 0 {
            return "now"
        }

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
            return "in less than 1m"
        }
    }

    /// Format time since a past date
    /// - Parameter date: Past date
    /// - Returns: Human-readable string (e.g., "15m ago", "2h 30m ago")
    static func formatTimeSince(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval <= 0 {
            return "just now"
        }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m ago"
            }
            return "\(hours)h ago"
        } else if minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "just now"
        }
    }

    // MARK: - Relative Time Formatting

    /// Format a relative time description for a date
    /// - Parameter date: Date to describe
    /// - Returns: Relative description (e.g., "now", "in 15m", "15m ago", "at 2:30 PM")
    static func formatRelativeTime(_ date: Date) -> String {
        let interval = date.timeIntervalSince(Date())

        // Within 1 minute
        if abs(interval) < 60 {
            return "now"
        }

        // Future
        if interval > 0 {
            // Within next hour - show countdown
            if interval < 3600 {
                return formatTimeUntil(date)
            }
            // More than an hour away - show clock time
            return "at \(formatTime(date))"
        }

        // Past
        // Within last hour - show "ago"
        if abs(interval) < 3600 {
            return formatTimeSince(date)
        }

        // More than an hour ago - show clock time
        return "at \(formatTime(date))"
    }

    // MARK: - Progress Formatting

    /// Format progress percentage
    /// - Parameter progress: Progress value from 0.0 to 1.0
    /// - Returns: Percentage string (e.g., "75%")
    static func formatProgress(_ progress: Double) -> String {
        let percentage = Int(progress * 100)
        return "\(percentage)%"
    }

    /// Format remaining time with context
    /// - Parameters:
    ///   - remaining: Remaining time in seconds
    ///   - total: Total duration in seconds
    /// - Returns: Contextual string (e.g., "15m left of 30m", "5m remaining")
    static func formatRemainingTime(_ remaining: TimeInterval, total: TimeInterval) -> String {
        let remainingStr = formatDuration(remaining, style: .abbreviated)

        if remaining <= 0 {
            return "completed"
        }

        if remaining < 60 {
            return "finishing up"
        }

        return "\(remainingStr) remaining"
    }
}

// MARK: - TimeInterval Extension

extension TimeInterval {
    /// Convert TimeInterval to abbreviated string
    var abbreviated: String {
        TimeFormatter.formatDuration(self, style: .abbreviated)
    }

    /// Convert TimeInterval to full string
    var full: String {
        TimeFormatter.formatDuration(self, style: .full)
    }

    /// Convert TimeInterval to compact string
    var compact: String {
        TimeFormatter.formatDuration(self, style: .compact)
    }

    /// Convert TimeInterval to timer display string
    var timerDisplay: String {
        TimeFormatter.formatDuration(self, style: .timer)
    }
}

// MARK: - Date Extension

extension Date {
    /// Format this date as a time string
    var timeString: String {
        TimeFormatter.formatTime(self)
    }

    /// Format this date as date and time string
    var dateTimeString: String {
        TimeFormatter.formatDateTime(self)
    }

    /// Format relative time description for this date
    var relativeTimeString: String {
        TimeFormatter.formatRelativeTime(self)
    }

    /// Format time until this date (if future)
    var timeUntilString: String {
        TimeFormatter.formatTimeUntil(self)
    }

    /// Format time since this date (if past)
    var timeSinceString: String {
        TimeFormatter.formatTimeSince(self)
    }
}
