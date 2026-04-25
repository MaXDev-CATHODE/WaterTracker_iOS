// WaterTrackerWidget.swift — Widget Extension target
//
// Defines the timeline entry, provider, widget configuration, and bundle entry point.

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

/// Snapshot of data displayed by the widget at a given point in time.
struct WaterTrackerEntry: TimelineEntry {
    /// The date associated with this entry (required by TimelineEntry).
    let date: Date
    /// Current daily water intake in ml.
    let dailyIntake: Int
    /// Daily water goal in ml.
    let dailyGoal: Int
    /// Default portion size shown on the "+" button in ml.
    let defaultPortion: Int
}

// MARK: - Timeline Provider

/// Provides timeline entries to WidgetKit by reading from the shared AppGroup store.
struct WaterTrackerProvider: TimelineProvider {

    // MARK: Placeholder

    /// Returns a placeholder entry used while the widget loads for the first time.
    func placeholder(in context: Context) -> WaterTrackerEntry {
        WaterTrackerEntry(
            date: .now,
            dailyIntake: 1200,
            dailyGoal: 2000,
            defaultPortion: 250
        )
    }

    // MARK: Snapshot

    /// Returns a single entry for transient situations (e.g. widget gallery preview).
    func getSnapshot(in context: Context,
                     completion: @escaping (WaterTrackerEntry) -> Void) {
        completion(currentEntry())
    }

    // MARK: Timeline

    /// Builds a timeline with one entry and schedules the next refresh at midnight.
    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<WaterTrackerEntry>) -> Void) {
        let store = AppGroupStore.shared

        // Reset daily intake if the last entry was recorded on a previous calendar day.
        if store.shouldResetForNewDay() {
            store.resetDailyIntake()
        }

        let entry = currentEntry()

        // Schedule the next automatic refresh at the start of the next calendar day.
        var midnight = Calendar.current.startOfDay(for: .now)
        midnight = Calendar.current.date(byAdding: .day, value: 1, to: midnight)!

        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }

    // MARK: Private helpers

    /// Reads the current values from the shared AppGroup store and builds an entry.
    private func currentEntry() -> WaterTrackerEntry {
        let store = AppGroupStore.shared
        return WaterTrackerEntry(
            date: .now,
            dailyIntake: store.dailyIntake,
            dailyGoal: store.dailyGoal,
            defaultPortion: store.defaultPortion
        )
    }
}

// MARK: - Widget Configuration

/// The widget that displays daily water intake progress and an interactive "+" button.
struct WaterTrackerWidget: Widget {

    let kind = "WaterTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WaterTrackerProvider()) { entry in
            WaterTrackerView(entry: entry)
        }
        .configurationDisplayName("WaterTracker")
        .description("Śledź dzienne spożycie wody.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle

/// Entry point for the Widget Extension — registers all widgets provided by this extension.
@main
struct WaterTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        WaterTrackerWidget()
    }
}
