// WaterStore.swift — App target only
//
// ObservableObject connecting AppGroupStore with SwiftUI views.
// Runs on the main actor to ensure all @Published updates happen on the main thread.

import SwiftUI
import WidgetKit

@MainActor
final class WaterStore: ObservableObject {

    // MARK: - Published properties

    /// Current daily water intake in ml (read-only from outside).
    @Published private(set) var dailyIntake: Int

    /// Daily water goal in ml (read-only from outside).
    @Published private(set) var dailyGoal: Int

    /// Default portion size in ml (read-only from outside).
    @Published private(set) var defaultPortion: Int

    /// Validation error message for the daily goal field; nil when valid.
    @Published var goalError: String?

    /// Validation error message for the default portion field; nil when valid.
    @Published var portionError: String?

    // MARK: - Private store

    private let store = AppGroupStore.shared

    // MARK: - Initializer

    init() {
        // Read initial values from the shared App Group store.
        self.dailyIntake    = store.dailyIntake
        self.dailyGoal      = store.dailyGoal
        self.defaultPortion = store.defaultPortion
        // Reset daily intake if the app is opened on a new calendar day.
        checkAndResetIfNewDay()
    }

    // MARK: - Actions

    /// Adds the given portion to the daily intake and refreshes the widget timeline.
    func addPortion(_ portion: Int) {
        dailyIntake = store.addPortion(portion)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Subtracts the default portion from the daily intake (floors at 0) and refreshes the widget.
    func subtractLastPortion() {
        dailyIntake = store.subtractPortion(defaultPortion)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Validates and saves a new daily goal.
    /// Sets `goalError` when the value is out of the accepted range (100–10 000 ml).
    func saveDailyGoal(_ value: Int) {
        if store.setDailyGoal(value) {
            dailyGoal = value
            goalError = nil
            WidgetCenter.shared.reloadAllTimelines()
        } else {
            goalError = "Cel musi być między 100 a 10 000 ml."
        }
    }

    /// Validates and saves a new default portion size.
    /// Sets `portionError` when the value is out of the accepted range (10–2 000 ml).
    func saveDefaultPortion(_ value: Int) {
        if store.setDefaultPortion(value) {
            defaultPortion = value
            portionError = nil
            WidgetCenter.shared.reloadAllTimelines()
        } else {
            portionError = "Porcja musi być między 10 a 2 000 ml."
        }
    }

    // MARK: - Computed properties

    /// Progress ratio clamped to [0.0, 1.0].
    /// Returns 0.0 when dailyGoal is zero or negative to avoid division by zero.
    var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1.0, Double(dailyIntake) / Double(dailyGoal))
    }

    /// Returns true when the daily intake has reached or exceeded the daily goal.
    var isGoalReached: Bool { dailyIntake >= dailyGoal }

    // MARK: - Daily reset

    /// Resets the daily intake to 0 if the last recorded entry was on a previous calendar day.
    func checkAndResetIfNewDay() {
        if store.shouldResetForNewDay() {
            store.resetDailyIntake()
            dailyIntake = 0
        }
    }
}
