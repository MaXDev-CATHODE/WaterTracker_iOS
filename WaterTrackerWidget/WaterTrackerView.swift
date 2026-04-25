// WaterTrackerView.swift — Widget Extension target
//
// SwiftUI view rendered inside the widget for systemSmall and systemMedium families.

import SwiftUI
import WidgetKit

/// The main view of the WaterTracker widget.
/// Displays a progress bar, intake/goal label, an interactive "+" button,
/// and a completion indicator when the daily goal has been reached.
struct WaterTrackerView: View {

    /// The timeline entry providing the data to display.
    let entry: WaterTrackerEntry

    // MARK: - Computed properties

    /// Progress ratio in [0.0, 1.0].
    /// Returns 0.0 when dailyGoal is zero to avoid division by zero.
    private var progress: Double {
        guard entry.dailyGoal > 0 else { return 0 }
        return min(1.0, Double(entry.dailyIntake) / Double(entry.dailyGoal))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {

            // Progress bar — green when goal reached, blue otherwise
            ProgressView(value: progress)
                .tint(progress >= 1.0 ? .green : .blue)

            // Intake / goal label
            Text("\(entry.dailyIntake) / \(entry.dailyGoal) ml")
                .font(.caption)

            // Interactive "+" button using AppIntent (iOS 17+)
            Button(intent: AddWaterIntent()) {
                Label("+\(entry.defaultPortion) ml", systemImage: "drop.fill")
            }
            .buttonStyle(.borderedProminent)

            // Completion indicator — shown only when the daily goal is reached
            if progress >= 1.0 {
                Label("Cel osiągnięty!", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .font(.caption2)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
