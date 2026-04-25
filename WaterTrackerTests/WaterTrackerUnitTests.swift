// WaterTrackerUnitTests.swift — Unit tests for AppGroupStore and WaterLogic
//
// Verifies concrete scenarios, default values, boundary conditions, and
// error-handling behaviour. Complements the property-based tests in
// WaterLogicPropertyTests.swift and AppGroupStorePropertyTests.swift.
//
// AppGroupStore tests use isolated UserDefaults suites created via
// AppGroupStore.makeForTesting(suiteName:) and cleaned up with defer.

import XCTest
@testable import WaterTrackerShared

// MARK: - WaterLogic Unit Tests

final class WaterLogicUnitTests: XCTestCase {

    // MARK: Default values

    /// Verifies that StoreDefault constants match the specified defaults.
    /// Validates: Requirements 1.5, 2.5
    func testDefaultValues() {
        XCTAssertEqual(StoreDefault.dailyGoal,      2000, "Default daily goal should be 2000 ml")
        XCTAssertEqual(StoreDefault.defaultPortion, 250,  "Default portion should be 250 ml")
        XCTAssertEqual(StoreDefault.dailyIntake,    0,    "Default daily intake should be 0 ml")
    }

    // MARK: computeProgress

    /// computeProgress with zero intake should return 0.0.
    /// Validates: Requirement 3.3
    func testComputeProgressZeroIntake() {
        let result = computeProgress(intake: 0, goal: 2000)
        XCTAssertEqual(result, 0.0, accuracy: 1e-9,
                       "Progress should be 0.0 when intake is 0")
    }

    /// computeProgress when intake equals goal should return exactly 1.0.
    /// Validates: Requirement 3.4
    func testComputeProgressGoalReached() {
        let result = computeProgress(intake: 2000, goal: 2000)
        XCTAssertEqual(result, 1.0, accuracy: 1e-9,
                       "Progress should be 1.0 when intake equals goal")
    }

    /// computeProgress when intake exceeds goal should be clamped to 1.0.
    /// Validates: Requirement 3.4
    func testComputeProgressExceedsGoal() {
        let result = computeProgress(intake: 3000, goal: 2000)
        XCTAssertEqual(result, 1.0, accuracy: 1e-9,
                       "Progress should be clamped to 1.0 when intake exceeds goal")
    }

    // MARK: applySubtraction

    /// Subtracting from zero intake should return 0 (floor behaviour).
    /// Validates: Requirement 4.7
    func testApplySubtractionAtZero() {
        let result = applySubtraction(intake: 0, portion: 250)
        XCTAssertEqual(result, 0,
                       "Subtracting from 0 intake should return 0, not a negative value")
    }

    /// Normal subtraction should return the correct difference.
    func testApplySubtractionNormal() {
        let result = applySubtraction(intake: 500, portion: 250)
        XCTAssertEqual(result, 250,
                       "500 - 250 should equal 250")
    }

    // MARK: isValidDailyGoal — boundary conditions

    /// Verifies the exact boundaries of the valid daily goal range (100–10 000 ml).
    func testIsValidDailyGoalBoundaries() {
        XCTAssertFalse(isValidDailyGoal(99),     "99 ml should be rejected (below minimum 100)")
        XCTAssertTrue(isValidDailyGoal(100),     "100 ml should be accepted (minimum boundary)")
        XCTAssertTrue(isValidDailyGoal(10_000),  "10 000 ml should be accepted (maximum boundary)")
        XCTAssertFalse(isValidDailyGoal(10_001), "10 001 ml should be rejected (above maximum 10 000)")
    }

    // MARK: isValidPortion — boundary conditions

    /// Verifies the exact boundaries of the valid portion range (10–2 000 ml).
    func testIsValidPortionBoundaries() {
        XCTAssertFalse(isValidPortion(9),    "9 ml should be rejected (below minimum 10)")
        XCTAssertTrue(isValidPortion(10),    "10 ml should be accepted (minimum boundary)")
        XCTAssertTrue(isValidPortion(2_000), "2 000 ml should be accepted (maximum boundary)")
        XCTAssertFalse(isValidPortion(2_001),"2 001 ml should be rejected (above maximum 2 000)")
    }
}

// MARK: - AppGroupStore Unit Tests

final class AppGroupStoreUnitTests: XCTestCase {

    // MARK: Default values on a fresh store

    /// A fresh store backed by an isolated suite should return all default values.
    /// Validates: Requirements 1.5, 2.5
    func testFreshStoreDefaultValues() {
        let suiteName = "unit-test.\(UUID().uuidString)"
        let store = AppGroupStore.makeForTesting(suiteName: suiteName)
        defer {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }

        XCTAssertEqual(store.dailyGoal,      2000, "Fresh store should return default dailyGoal of 2000 ml")
        XCTAssertEqual(store.defaultPortion, 250,  "Fresh store should return default defaultPortion of 250 ml")
        XCTAssertEqual(store.dailyIntake,    0,    "Fresh store should return default dailyIntake of 0 ml")
    }

    // MARK: App Group fallback

    /// When suiteName is nil, isAppGroupAvailable should be false (standard UserDefaults fallback).
    /// Validates: Requirement 6.4
    func testFallbackWhenAppGroupUnavailable() {
        let store = AppGroupStore.makeForTesting(suiteName: nil)
        XCTAssertFalse(store.isAppGroupAvailable,
                       "isAppGroupAvailable should be false when suiteName is nil")
    }

    // MARK: subtractPortion at zero

    /// Subtracting a portion when dailyIntake is 0 should return 0 (floor behaviour).
    /// Validates: Requirement 4.7
    func testSubtractPortionAtZero() {
        let suiteName = "unit-test.\(UUID().uuidString)"
        let store = AppGroupStore.makeForTesting(suiteName: suiteName)
        defer {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }

        XCTAssertEqual(store.dailyIntake, 0, "Precondition: dailyIntake should start at 0")

        let result = store.subtractPortion(250)
        XCTAssertEqual(result, 0,
                       "subtractPortion(250) on zero intake should return 0, not negative")
        XCTAssertEqual(store.dailyIntake, 0,
                       "dailyIntake should remain 0 after subtracting from zero")
    }

    // MARK: setDailyGoal — out-of-range rejection

    /// setDailyGoal with a value outside the valid range should return false and leave dailyGoal unchanged.
    /// Validates: Requirement 1.3
    func testSetDailyGoalOutOfRange() {
        let suiteName = "unit-test.\(UUID().uuidString)"
        let store = AppGroupStore.makeForTesting(suiteName: suiteName)
        defer {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }

        let accepted = store.setDailyGoal(50)
        XCTAssertFalse(accepted,
                       "setDailyGoal(50) should return false — value is below minimum 100")
        XCTAssertEqual(store.dailyGoal, 2000,
                       "dailyGoal should remain at default 2000 after rejecting out-of-range value")
    }

    // MARK: setDefaultPortion — out-of-range rejection

    /// setDefaultPortion with a value outside the valid range should return false and leave defaultPortion unchanged.
    /// Validates: Requirement 2.3
    func testSetDefaultPortionOutOfRange() {
        let suiteName = "unit-test.\(UUID().uuidString)"
        let store = AppGroupStore.makeForTesting(suiteName: suiteName)
        defer {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }

        let accepted = store.setDefaultPortion(5)
        XCTAssertFalse(accepted,
                       "setDefaultPortion(5) should return false — value is below minimum 10")
        XCTAssertEqual(store.defaultPortion, 250,
                       "defaultPortion should remain at default 250 after rejecting out-of-range value")
    }

    // MARK: addPortion

    /// addPortion should increase dailyIntake by exactly the given portion.
    /// Validates: Requirements 3.1, 4.5
    func testAddPortionUpdatesIntake() {
        let suiteName = "unit-test.\(UUID().uuidString)"
        let store = AppGroupStore.makeForTesting(suiteName: suiteName)
        defer {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }

        XCTAssertEqual(store.dailyIntake, 0, "Precondition: dailyIntake should start at 0")

        store.addPortion(250)
        XCTAssertEqual(store.dailyIntake, 250,
                       "dailyIntake should be 250 after adding a 250 ml portion to a zero intake")
    }

    // MARK: resetDailyIntake

    /// resetDailyIntake should set dailyIntake back to 0 regardless of the current value.
    /// Validates: Requirement 5.3
    func testResetDailyIntake() {
        let suiteName = "unit-test.\(UUID().uuidString)"
        let store = AppGroupStore.makeForTesting(suiteName: suiteName)
        defer {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }

        store.addPortion(500)
        XCTAssertEqual(store.dailyIntake, 500, "Precondition: dailyIntake should be 500 after adding 500 ml")

        store.resetDailyIntake()
        XCTAssertEqual(store.dailyIntake, 0,
                       "dailyIntake should be 0 after resetDailyIntake()")
    }

    // MARK: shouldResetForNewDay — first launch

    /// A fresh store with no lastEntryDate should not trigger a daily reset.
    /// Validates: Requirement 5.3
    func testShouldNotResetOnFirstLaunch() {
        let suiteName = "unit-test.\(UUID().uuidString)"
        let store = AppGroupStore.makeForTesting(suiteName: suiteName)
        defer {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }

        XCTAssertNil(store.lastEntryDate,
                     "Precondition: lastEntryDate should be nil on first launch")
        XCTAssertFalse(store.shouldResetForNewDay(),
                       "shouldResetForNewDay() should return false when lastEntryDate is nil (first launch)")
    }
}
