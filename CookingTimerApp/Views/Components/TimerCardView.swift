//
//  TimerCardView.swift
//  CookingTimerApp
//
//  Card display for individual cooking timer
//

import SwiftUI

/// Individual timer display card
struct TimerCardView: View {
    @ObservedObject var timer: CookingTimer

    var body: some View {
        HStack(spacing: 16) {
            // Progress ring
            ProgressRingView(
                progress: timer.progress,
                color: stepColor,
                size: 60,
                lineWidth: 6,
                timeText: timer.formattedRemainingTime
            )

            // Timer info
            VStack(alignment: .leading, spacing: 4) {
                // Step description
                Text(timer.step.description)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                // Status/timing info
                Text(timer.statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Step type badge
                HStack(spacing: 8) {
                    Image(systemName: timer.step.stepType.iconName)
                        .font(.caption)

                    Text(timer.step.stepType.displayName)
                        .font(.caption)
                }
                .foregroundColor(stepColor)
            }

            Spacer()

            // State badge
            stateBadge
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(timer.statusMessage)
    }

    // MARK: - Computed Properties

    private var stepColor: Color {
        switch timer.step.stepType {
        case .preparation:
            return .blue
        case .cooking:
            return .orange
        case .baking:
            return .red
        case .resting:
            return .purple
        case .assembly:
            return .green
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(nsColor: .controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }

    @ViewBuilder
    private var stateBadge: some View {
        let (icon, color) = stateIconAndColor

        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(timer.state.description)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2))
        .foregroundColor(color)
        .cornerRadius(8)
    }

    private var stateIconAndColor: (String, Color) {
        switch timer.state {
        case .ready:
            return ("clock", .blue)
        case .running:
            return ("play.circle.fill", .green)
        case .paused:
            return ("pause.circle.fill", .orange)
        case .completed:
            return ("checkmark.circle.fill", .gray)
        case .cancelled:
            return ("xmark.circle.fill", .red)
        }
    }

    private var accessibilityLabel: String {
        "\(timer.step.stepType.displayName): \(timer.step.description)"
    }
}

// MARK: - Previews

struct TimerCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            TimerCardView(timer: .sample)
            TimerCardView(timer: .running)
            TimerCardView(timer: .completed)
        }
        .padding()
        .frame(width: 400)
        .previewLayout(.sizeThatFits)
    }
}
