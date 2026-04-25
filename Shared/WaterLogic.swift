// WaterLogic.swift — Shared between App and Widget targets
//
// Pure functions for validation and calculations.
// No side effects, no external state dependencies.

import Foundation

// MARK: - Storage Keys

/// Keys for shared UserDefaults storage (App Group)
enum StoreKey {
    static let dailyIntake    = "dailyIntake"
    static let dailyGoal      = "dailyGoal"
    static let defaultPortion = "defaultPortion"
    static let lastEntryDate  = "lastEntryDate"
}

// MARK: - Default Values

/// Default values used when AppGroup data is unavailable or not yet set
enum StoreDefault {
    static let dailyGoal      = 2000  // ml
    static let defaultPortion = 250   // ml
    static let dailyIntake    = 0     // ml
}

// MARK: - Validation Ranges

/// Validation ranges for user-provided values
enum StoreRange {
    static let dailyGoal = 100...10_000  // ml
    static let portion   = 10...2_000    // ml
}

// MARK: - Pure Validation Functions

/// Returns true if the given value is a valid daily goal (100–10 000 ml).
func isValidDailyGoal(_ value: Int) -> Bool {
    StoreRange.dailyGoal.contains(value)
}

/// Returns true if the given value is a valid portion size (10–2 000 ml).
func isValidPortion(_ value: Int) -> Bool {
    StoreRange.portion.contains(value)
}

// MARK: - Pure Calculation Functions

/// Computes the progress ratio clamped to [0.0, 1.0].
/// Returns 0.0 when goal is zero or negative to avoid division by zero.
func computeProgress(intake: Int, goal: Int) -> Double {
    guard goal > 0 else { return 0.0 }
    return min(1.0, Double(intake) / Double(goal))
}

/// Subtracts portion from intake, flooring the result at 0.
/// Ensures DailyIntake never goes negative.
func applySubtraction(intake: Int, portion: Int) -> Int {
    max(0, intake - portion)
}
