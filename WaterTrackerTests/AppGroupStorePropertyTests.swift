// AppGroupStorePropertyTests.swift — Property-based tests for AppGroupStore
//
// Uses SwiftCheck to verify universal properties of AppGroupStore across
// randomly generated inputs. Each property corresponds to a correctness
// property defined in the design document.
//
// Each test creates an isolated AppGroupStore instance via
// AppGroupStore.makeForTesting(suiteName:) to avoid cross-test interference.
// The UserDefaults suite is cleaned up after every test.

import XCTest
import SwiftCheck
@testable import WaterTrackerShared

final class AppGroupStorePropertyTests: XCTestCase {

    // MARK: - Property 3: Round-trip DailyGoal
    // Feature: water-tracker-ios, Property 3: Round-trip write/read of DailyGoal via AppGroup

    /// Validates: Requirements 1.2, 6.1
    func testDailyGoalRoundTrip() {
        property("setDailyGoal followed by dailyGoal read returns the same value") <- forAll(
            Gen<Int>.choose((100, 10_000))  // valid DailyGoal range
        ) { goal in
            let suiteName = "test.\(UUID().uuidString)"
            let store = AppGroupStore.makeForTesting(suiteName: suiteName)
            defer {
                UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
            }

            let accepted = store.setDailyGoal(goal)
            return accepted && store.dailyGoal == goal
        }
    }

    // MARK: - Property 4: Round-trip DefaultPortion
    // Feature: water-tracker-ios, Property 4: Round-trip write/read of DefaultPortion via AppGroup

    /// Validates: Requirements 2.2, 6.1
    func testDefaultPortionRoundTrip() {
        property("setDefaultPortion followed by defaultPortion read returns the same value") <- forAll(
            Gen<Int>.choose((10, 2_000))  // valid DefaultPortion range
        ) { portion in
            let suiteName = "test.\(UUID().uuidString)"
            let store = AppGroupStore.makeForTesting(suiteName: suiteName)
            defer {
                UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
            }

            let accepted = store.setDefaultPortion(portion)
            return accepted && store.defaultPortion == portion
        }
    }

    // MARK: - Property 5: Adding a portion increases DailyIntake by exactly that portion
    // Feature: water-tracker-ios, Property 5: addPortion increases dailyIntake by exactly the portion

    /// Validates: Requirements 3.1, 4.5
    func testAddPortionIncreasesIntakeByExactAmount() {
        property("addPortion(portion) increases dailyIntake by exactly portion") <- forAll(
            Gen<Int>.choose((0, 100_000)),  // arbitrary non-negative starting intake
            Gen<Int>.choose((10, 2_000))    // valid portion range
        ) { intake, portion in
            let suiteName = "test.\(UUID().uuidString)"
            let store = AppGroupStore.makeForTesting(suiteName: suiteName)
            defer {
                UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
            }

            // Set the initial intake directly via addPortion from zero
            // (store starts at 0, so we add `intake` first to reach the desired starting value)
            if intake > 0 {
                UserDefaults(suiteName: suiteName)?.set(intake, forKey: "dailyIntake")
            }

            let before = store.dailyIntake
            store.addPortion(portion)
            let after = store.dailyIntake

            return after == before + portion
        }
    }

    // MARK: - Property 8: New day detection
    // Feature: water-tracker-ios, Property 8: shouldResetForNewDay returns true for past dates, false for nil

    /// Validates: Requirements 5.1, 5.2, 5.3
    func testNewDayDetection() {
        // Part A: lastEntryDate set to daysAgo days in the past → shouldResetForNewDay() == true
        property("shouldResetForNewDay returns true when lastEntryDate is daysAgo days in the past") <- forAll(
            Gen<Int>.choose((1, 365))  // number of days ago (always a previous day)
        ) { daysAgo in
            let suiteName = "test.\(UUID().uuidString)"
            let store = AppGroupStore.makeForTesting(suiteName: suiteName)
            defer {
                UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
            }

            let calendar = Calendar.current
            let pastDate = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            // Write the past date directly into UserDefaults
            UserDefaults(suiteName: suiteName)?.set(pastDate, forKey: "lastEntryDate")

            return store.shouldResetForNewDay() == true
        }

        // Part B: lastEntryDate == nil → shouldResetForNewDay() == false
        let suiteName = "test.\(UUID().uuidString)"
        let store = AppGroupStore.makeForTesting(suiteName: suiteName)
        defer {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }
        // No lastEntryDate written — store starts clean
        XCTAssertNil(store.lastEntryDate, "lastEntryDate should be nil for a fresh store")
        XCTAssertFalse(store.shouldResetForNewDay(),
                       "shouldResetForNewDay should return false when lastEntryDate is nil")
    }

    // MARK: - Property 9: Fallback to default values on a fresh store
    // Feature: water-tracker-ios, Property 9: Fresh AppGroupStore returns default values

    /// Validates: Requirements 6.4, 1.5, 2.5
    func testFreshStoreReturnsDefaults() {
        property("A fresh AppGroupStore returns dailyGoal=2000, defaultPortion=250, dailyIntake=0") <- forAll(
            // Generate a unique UUID string to ensure a truly fresh suite each iteration
            Gen<UInt32>.choose((0, UInt32.max))
        ) { _ in
            let suiteName = "test.\(UUID().uuidString)"
            let store = AppGroupStore.makeForTesting(suiteName: suiteName)
            defer {
                UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
            }

            return store.dailyGoal == 2000
                && store.defaultPortion == 250
                && store.dailyIntake == 0
        }
    }

    // MARK: - Property 10: Round-trip of all AppGroup values
    // Feature: water-tracker-ios, Property 10: Round-trip write/read of all AppGroup values

    /// Validates: Requirements 6.1, 6.2
    func testAllValuesRoundTrip() {
        property("Writing goal, portion, and intake then reading them back returns the same values") <- forAll(
            Gen<Int>.choose((100, 10_000)),   // valid DailyGoal
            Gen<Int>.choose((10, 2_000)),     // valid DefaultPortion
            Gen<Int>.choose((0, 100_000))     // arbitrary non-negative DailyIntake
        ) { goal, portion, intake in
            let suiteName = "test.\(UUID().uuidString)"
            let store = AppGroupStore.makeForTesting(suiteName: suiteName)
            defer {
                UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
            }

            // Write all values
            let goalAccepted    = store.setDailyGoal(goal)
            let portionAccepted = store.setDefaultPortion(portion)
            // Write intake directly (no public setter — use addPortion from 0)
            UserDefaults(suiteName: suiteName)?.set(intake, forKey: "dailyIntake")

            // Read all values back from the same instance
            let readGoal    = store.dailyGoal
            let readPortion = store.defaultPortion
            let readIntake  = store.dailyIntake

            return goalAccepted
                && portionAccepted
                && readGoal    == goal
                && readPortion == portion
                && readIntake  == intake
        }
    }
}
