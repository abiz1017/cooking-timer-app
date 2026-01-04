//
//  ProgressRingView.swift
//  CookingTimerApp
//
//  Circular progress ring showing timer countdown
//

import SwiftUI

/// Circular progress indicator with countdown display
struct ProgressRingView: View {
    let progress: Double  // 0.0 to 1.0
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat
    let showTime: Bool
    let timeText: String?

    init(
        progress: Double,
        color: Color,
        size: CGFloat = 60,
        lineWidth: CGFloat = 6,
        showTime: Bool = true,
        timeText: String? = nil
    ) {
        self.progress = max(0, min(1, progress))
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
        self.showTime = showTime
        self.timeText = timeText
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            // Time text in center
            if showTime, let timeText = timeText {
                Text(timeText)
                    .font(.system(size: size * 0.25, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Previews

struct ProgressRingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // Different progress levels
            HStack(spacing: 20) {
                ProgressRingView(progress: 0.25, color: .blue, timeText: "15:00")
                ProgressRingView(progress: 0.5, color: .green, timeText: "7:30")
                ProgressRingView(progress: 0.75, color: .orange, timeText: "5:00")
                ProgressRingView(progress: 1.0, color: .gray, timeText: "0:00")
            }

            // Different sizes
            HStack(spacing: 20) {
                ProgressRingView(progress: 0.6, color: .blue, size: 40, lineWidth: 4, timeText: "12:00")
                ProgressRingView(progress: 0.6, color: .blue, size: 80, lineWidth: 8, timeText: "12:00")
                ProgressRingView(progress: 0.6, color: .blue, size: 120, lineWidth: 10, timeText: "12:00")
            }

            // Different colors
            HStack(spacing: 20) {
                ProgressRingView(progress: 0.5, color: .blue, timeText: "10:00")
                ProgressRingView(progress: 0.5, color: .green, timeText: "10:00")
                ProgressRingView(progress: 0.5, color: .orange, timeText: "10:00")
                ProgressRingView(progress: 0.5, color: .red, timeText: "10:00")
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
