//
//  DurationParser.swift
//  CookingTimerApp
//
//  Parses duration strings from various formats into TimeInterval
//

import Foundation

/// Utility for parsing time duration strings into TimeInterval
struct DurationParser {
    /// Parse an ISO 8601 duration string (e.g., "PT30M", "PT2H15M")
    /// - Parameter isoString: ISO 8601 duration format string
    /// - Returns: TimeInterval in seconds, or nil if parsing fails
    static func parseISO8601Duration(_ isoString: String) -> TimeInterval? {
        // ISO 8601 duration format: P[n]Y[n]M[n]DT[n]H[n]M[n]S
        // We care about hours (H), minutes (M), and seconds (S) after the T

        guard isoString.hasPrefix("P") else { return nil }

        let pattern = #"PT?(?:(\d+(?:\.\d+)?)H)?(?:(\d+(?:\.\d+)?)M)?(?:(\d+(?:\.\d+)?)S)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let nsString = isoString as NSString
        let range = NSRange(location: 0, length: nsString.length)

        guard let match = regex.firstMatch(in: isoString, options: [], range: range) else {
            return nil
        }

        var totalSeconds: TimeInterval = 0

        // Extract hours
        if match.range(at: 1).location != NSNotFound {
            let hoursString = nsString.substring(with: match.range(at: 1))
            if let hours = Double(hoursString) {
                totalSeconds += hours * 3600
            }
        }

        // Extract minutes
        if match.range(at: 2).location != NSNotFound {
            let minutesString = nsString.substring(with: match.range(at: 2))
            if let minutes = Double(minutesString) {
                totalSeconds += minutes * 60
            }
        }

        // Extract seconds
        if match.range(at: 3).location != NSNotFound {
            let secondsString = nsString.substring(with: match.range(at: 3))
            if let seconds = Double(secondsString) {
                totalSeconds += seconds
            }
        }

        return totalSeconds > 0 ? totalSeconds : nil
    }

    /// Parse natural language duration strings (e.g., "30 minutes", "2 hours", "1h 30m")
    /// - Parameter naturalString: Human-readable duration string
    /// - Returns: TimeInterval in seconds, or nil if parsing fails
    static func parseNaturalDuration(_ naturalString: String) -> TimeInterval? {
        let lowercased = naturalString.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        var totalSeconds: TimeInterval = 0

        // Pattern for hours: "2 hours", "2h", "2 hrs"
        let hourPatterns = [
            #"(\d+(?:\.\d+)?)\s*(?:hour|hours|hr|hrs|h)\b"#
        ]

        // Pattern for minutes: "30 minutes", "30m", "30 mins"
        let minutePatterns = [
            #"(\d+(?:\.\d+)?)\s*(?:minute|minutes|min|mins|m)\b"#
        ]

        // Pattern for seconds: "45 seconds", "45s", "45 secs"
        let secondPatterns = [
            #"(\d+(?:\.\d+)?)\s*(?:second|seconds|sec|secs|s)\b"#
        ]

        // Extract hours
        for pattern in hourPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: lowercased, options: [], range: NSRange(lowercased.startIndex..., in: lowercased)),
               let range = Range(match.range(at: 1), in: lowercased),
               let hours = Double(lowercased[range]) {
                totalSeconds += hours * 3600
            }
        }

        // Extract minutes
        for pattern in minutePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: lowercased, options: [], range: NSRange(lowercased.startIndex..., in: lowercased)),
               let range = Range(match.range(at: 1), in: lowercased),
               let minutes = Double(lowercased[range]) {
                totalSeconds += minutes * 60
            }
        }

        // Extract seconds
        for pattern in secondPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: lowercased, options: [], range: NSRange(lowercased.startIndex..., in: lowercased)),
               let range = Range(match.range(at: 1), in: lowercased),
               let seconds = Double(lowercased[range]) {
                totalSeconds += seconds
            }
        }

        // Handle range formats like "2-3 hours" - use the midpoint
        let rangePattern = #"(\d+)\s*-\s*(\d+)\s*(?:hour|hours|hr|hrs|h|minute|minutes|min|mins|m)\b"#
        if let regex = try? NSRegularExpression(pattern: rangePattern, options: []),
           let match = regex.firstMatch(in: lowercased, options: [], range: NSRange(lowercased.startIndex..., in: lowercased)),
           let range1 = Range(match.range(at: 1), in: lowercased),
           let range2 = Range(match.range(at: 2), in: lowercased),
           let min = Double(lowercased[range1]),
           let max = Double(lowercased[range2]) {
            let midpoint = (min + max) / 2

            // Determine if it's hours or minutes
            if lowercased.contains("hour") || lowercased.contains("hr") {
                totalSeconds = midpoint * 3600
            } else {
                totalSeconds = midpoint * 60
            }
        }

        return totalSeconds > 0 ? totalSeconds : nil
    }

    /// Parse any duration string, trying multiple formats
    /// - Parameter durationString: Duration string in any supported format
    /// - Returns: TimeInterval in seconds, or nil if all parsing attempts fail
    static func parse(_ durationString: String) -> TimeInterval? {
        // Try ISO 8601 first
        if let iso = parseISO8601Duration(durationString) {
            return iso
        }

        // Try natural language
        if let natural = parseNaturalDuration(durationString) {
            return natural
        }

        // Try direct number parsing (assume minutes)
        if let number = Double(durationString) {
            return number * 60
        }

        return nil
    }

    /// Extract all duration mentions from a text string
    /// - Parameter text: Text that may contain duration mentions
    /// - Returns: Array of TimeIntervals found in the text
    static func extractDurations(from text: String) -> [TimeInterval] {
        var durations: [TimeInterval] = []

        // Look for ISO 8601 patterns
        let isoPattern = #"P(?:T(?:\d+H)?(?:\d+M)?(?:\d+S)?)"#
        if let regex = try? NSRegularExpression(pattern: isoPattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text),
                   let duration = parseISO8601Duration(String(text[range])) {
                    durations.append(duration)
                }
            }
        }

        // Look for natural language patterns
        let naturalPattern = #"\d+\s*(?:hour|hours|hr|hrs|h|minute|minutes|min|mins|m|second|seconds|sec|secs|s)\b"#
        if let regex = try? NSRegularExpression(pattern: naturalPattern, options: .caseInsensitive) {
            let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text),
                   let duration = parseNaturalDuration(String(text[range])) {
                    durations.append(duration)
                }
            }
        }

        return durations
    }

    /// Estimate duration for common cooking terms
    /// - Parameter term: Cooking action term (e.g., "simmer", "bake", "marinate")
    /// - Returns: Estimated TimeInterval, or nil if term not recognized
    static func estimateDurationForCookingTerm(_ term: String) -> TimeInterval? {
        let lowercased = term.lowercased()

        // Common cooking term durations (in seconds)
        let cookingTerms: [String: TimeInterval] = [
            "preheat": 600,           // 10 minutes
            "boil": 900,              // 15 minutes
            "simmer": 1200,           // 20 minutes
            "sauté": 300,             // 5 minutes
            "fry": 420,               // 7 minutes
            "bake": 2400,             // 40 minutes
            "roast": 3600,            // 1 hour
            "grill": 900,             // 15 minutes
            "steam": 600,             // 10 minutes
            "marinate": 1800,         // 30 minutes
            "chill": 7200,            // 2 hours
            "freeze": 14400,          // 4 hours
            "rest": 600,              // 10 minutes
            "cool": 900,              // 15 minutes
            "rise": 3600,             // 1 hour (for dough)
            "proof": 1800,            // 30 minutes
            "blanch": 180,            // 3 minutes
            "reduce": 900,            // 15 minutes
            "caramelize": 1200,       // 20 minutes
            "sear": 300,              // 5 minutes
            "brown": 420,             // 7 minutes
            "char": 300,              // 5 minutes
            "toast": 180,             // 3 minutes
            "melt": 300,              // 5 minutes
            "whisk": 120,             // 2 minutes
            "mix": 180,               // 3 minutes
            "stir": 120,              // 2 minutes
            "chop": 300,              // 5 minutes
            "dice": 360,              // 6 minutes
            "slice": 240,             // 4 minutes
            "mince": 300,             // 5 minutes
            "peel": 300,              // 5 minutes
            "grate": 180,             // 3 minutes
        ]

        for (cookingTerm, duration) in cookingTerms {
            if lowercased.contains(cookingTerm) {
                return duration
            }
        }

        return nil
    }
}
