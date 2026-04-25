// AppGroupStore.swift — Shared between App and Widget targets
//
// Singleton data layer responsible for all read/write operations
// on the shared UserDefaults (App Group). Used by both the App and Widget targets.

import Foundation

// MARK: - AppGroupStore

/// Singleton data layer for shared UserDefaults (App Group).
/// Accepts an optional suiteName for testability:
///   - suiteName != nil: attempts UserDefaults(suiteName:), falls back to .standard if unavailable
///   - suiteName == nil: uses UserDefaults.standard directly (for unit tests)
final class AppGroupStore {

    // MARK: - Singleton

    /// Shared singleton — uses the default App Group identifier.
    static let shared = AppGroupStore()

    /// App Group identifier — must match entitlements in both targets.
    static let appGroupID = "group.com.yourname.watertracker"

    // MARK: - Internal state

    private let defaults: UserDefaults

    /// Indicates whether the App Group UserDefaults suite is available.
    /// False when the App Group entitlement is missing (e.g. sideload without proper signing).
    private(set) var isAppGroupAvailable: Bool

    // MARK: - Initializer

    /// Designated initializer.
    /// - Parameter suiteName: The App Group suite name to use.
    ///   Pass `nil` to use `UserDefaults.standard` directly (useful in unit tests).
    ///   Defaults to `AppGroupStore.appGroupID` so the singleton works out of the box.
    private init(suiteName: String? = AppGroupStore.appGroupID) {
        if let name = suiteName {
            // Attempt to open the App Group suite; fall back to standard if unavailable.
            if let suite = UserDefaults(suiteName: name) {
                self.defaults = suite
                self.isAppGroupAvailable = true
            } else {
                // App Group unavailable — use standard UserDefaults as fallback.
                self.defaults = UserDefaults.standard
                self.isAppGroupAvailable = false
                print("[AppGroupStore] WARNING: App Group '\(name)' unavailable, using standard UserDefaults")
            }
        } else {
            // suiteName == nil: use standard UserDefaults directly (test mode).
            self.defaults = UserDefaults.standard
            self.isAppGroupAvailable = false
        }
    }

    // MARK: - Testable factory

    /// Creates a testable instance backed by an in-memory UserDefaults suite.
    /// - Parameter suiteName: A unique suite name for isolation between tests.
    ///   Pass `nil` to use `UserDefaults.standard`.
    static func makeForTesting(suiteName: String?) -> AppGroupStore {
        AppGroupStore(suiteName: suiteName)
    }

    // MARK: - Read

    /// Current daily water intake in ml. Returns 0 when the key has never been set.
    var dailyIntake: Int {
        defaults.integer(forKey: StoreKey.dailyIntake)
        // UserDefaults.integer(forKey:) returns 0 for missing keys — correct fallback.
    }

    /// Daily water goal in ml. Returns the stored value, or the default (2 000 ml) when 0 or unset.
    var dailyGoal: Int {
        let value = defaults.integer(forKey: StoreKey.dailyGoal)
        return value > 0 ? value : StoreDefault.dailyGoal
    }

    /// Default portion size in ml. Returns the stored value, or the default (250 ml) when 0 or unset.
    var defaultPortion: Int {
        let value = defaults.integer(forKey: StoreKey.defaultPortion)
        return value > 0 ? value : StoreDefault.defaultPortion
    }

    /// Date of the last recorded entry, or nil if no entry has been recorded yet.
    var lastEntryDate: Date? {
        defaults.object(forKey: StoreKey.lastEntryDate) as? Date
    }

    // MARK: - Write

    /// Adds the given portion to the current daily intake and records the current date.
    /// - Parameter portion: Amount of water to add in ml.
    /// - Returns: The new daily intake value.
    @discardableResult
    func addPortion(_ portion: Int) -> Int {
        let newValue = dailyIntake + portion
        defaults.set(newValue, forKey: StoreKey.dailyIntake)
        defaults.set(Date(), forKey: StoreKey.lastEntryDate)
        return newValue
    }

    /// Subtracts the given portion from the current daily intake, flooring at 0.
    /// Also records the current date as the last entry date.
    /// - Parameter portion: Amount of water to subtract in ml.
    /// - Returns: The new daily intake value (>= 0).
    @discardableResult
    func subtractPortion(_ portion: Int) -> Int {
        let newValue = max(0, dailyIntake - portion)
        defaults.set(newValue, forKey: StoreKey.dailyIntake)
        defaults.set(Date(), forKey: StoreKey.lastEntryDate)
        return newValue
    }

    /// Validates and persists a new daily goal value.
    /// - Parameter value: Desired daily goal in ml.
    /// - Returns: `true` if the value was accepted and saved; `false` if out of range (100–10 000 ml).
    @discardableResult
    func setDailyGoal(_ value: Int) -> Bool {
        guard isValidDailyGoal(value) else { return false }
        defaults.set(value, forKey: StoreKey.dailyGoal)
        return true
    }

    /// Validates and persists a new default portion value.
    /// - Parameter value: Desired default portion in ml.
    /// - Returns: `true` if the value was accepted and saved; `false` if out of range (10–2 000 ml).
    @discardableResult
    func setDefaultPortion(_ value: Int) -> Bool {
        guard isValidPortion(value) else { return false }
        defaults.set(value, forKey: StoreKey.defaultPortion)
        return true
    }

    /// Resets the daily intake to 0 and updates the last entry date to now.
    func resetDailyIntake() {
        defaults.set(0, forKey: StoreKey.dailyIntake)
        defaults.set(Date(), forKey: StoreKey.lastEntryDate)
    }

    // MARK: - Daily reset

    /// Returns `true` when the last recorded entry was on a previous calendar day,
    /// indicating that the daily intake counter should be reset.
    ///
    /// Returns `false` when `lastEntryDate` is nil (first launch — no reset needed).
    ///
    /// - Parameter calendar: The calendar used for day comparison. Defaults to `.current`.
    func shouldResetForNewDay(calendar: Calendar = .current) -> Bool {
        guard let last = lastEntryDate else { return false }
        return !calendar.isDateInToday(last)
    }
}
