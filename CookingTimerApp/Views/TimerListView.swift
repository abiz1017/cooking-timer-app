//
//  TimerListView.swift
//  CookingTimerApp
//
//  List view showing all timers grouped by status
//

import SwiftUI

/// Scrollable list of timer cards grouped by status
struct TimerListView: View {
    @ObservedObject var coordinator: TimerCoordinatorViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Upcoming timers
                if !coordinator.upcomingTimers.isEmpty {
                    timerSection(
                        title: "Upcoming",
                        icon: "clock.badge",
                        timers: coordinator.upcomingTimers,
                        color: .blue
                    )
                }

                // Active timers
                if !coordinator.activeTimers.isEmpty {
                    timerSection(
                        title: "In Progress",
                        icon: "play.circle.fill",
                        timers: coordinator.activeTimers,
                        color: .green
                    )
                }

                // Paused timers
                if !coordinator.pausedTimers.isEmpty {
                    timerSection(
                        title: "Paused",
                        icon: "pause.circle.fill",
                        timers: coordinator.pausedTimers,
                        color: .orange
                    )
                }

                // Completed timers
                if !coordinator.completedTimers.isEmpty {
                    timerSection(
                        title: "Completed",
                        icon: "checkmark.circle.fill",
                        timers: coordinator.completedTimers,
                        color: .gray
                    )
                }

                // Empty state
                if coordinator.timers.isEmpty {
                    emptyState
                }
            }
            .padding()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Timer list")
    }

    // MARK: - Subviews

    @ViewBuilder
    private func timerSection(
        title: String,
        icon: String,
        timers: [CookingTimer],
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)

                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("(\(timers.count))")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title), \(timers.count) timers")

            // Timer cards
            VStack(spacing: 12) {
                ForEach(timers) { timer in
                    TimerCardView(timer: timer)
                        .contextMenu {
                            contextMenuItems(for: timer)
                        }
                }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "timer")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Active Timers")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add a recipe to get started")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(60)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No active timers. Add a recipe to get started.")
    }

    @ViewBuilder
    private func contextMenuItems(for timer: CookingTimer) -> some View {
        if timer.state == .ready {
            Button("Start Now") {
                coordinator.startTimer(timer.id)
            }
        }

        if timer.state == .running {
            Button("Pause") {
                coordinator.pauseTimer(timer.id)
            }
        }

        if timer.state == .paused {
            Button("Resume") {
                coordinator.resumeTimer(timer.id)
            }
        }

        if timer.state.canCancel {
            Button("Cancel", role: .destructive) {
                coordinator.cancelTimer(timer.id)
            }
        }
    }
}

// MARK: - Previews

struct TimerListView_Previews: PreviewProvider {
    static var previews: some View {
        let coordinator = TimerCoordinatorViewModel()
        let recipe = Recipe.sample
        coordinator.loadRecipe(recipe)

        return TimerListView(coordinator: coordinator)
            .frame(width: 500, height: 600)
    }
}
