// WaterStoreTests.swift — Unit tests for WaterStore logic
//
// WaterStore (App target) is not available in the SPM test target, which only
// includes WaterTrackerShared. These tests therefore verify the same business
// logic that WaterStore delegates to AppGroupStore and WaterLogic:
//
//   • saveDailyGoal  → AppGroupStore.setDailyGoal(_:)
//   • saveDefaultPortion → AppGroupStore.setDefaultPortion(_:)
//   • addPortion     → AppGroupStore.addPortion(_:)
//   • progress       → computeProgress(intake:goal:)
//
// Each test uses an isolated AppGroupStore instance created via
// AppGroupStore.makeForTesting(suiteName:) and cleans up after itself.
//
// Validates: Requirements 1.3, 2.3, 3.3, 3.4, 4.5

import XCTest
@testable import WaterTrackerShared

// MARK: - WaterStore Logic Tests

final class WaterStoreTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a fresh isolated store and registers cleanup.
    private func makeStore() -> (AppGroupStore, String) {
        let suiteName = "waterstore-test.\(UUID().uuidString)"
        let store = AppGroupStore.makeForTesting(suiteName: suiteName)
        return (store, suiteName)
    }

    private func cleanup(suiteName: String) {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    // MARK: - Test 1: saveDailyGoal out of range sets error and does not change dailyGoal
    //
    // WaterStore.saveDailyGoal(50) should set goalError != nil and leave dailyGoal unchanged.
    // Validates: Requirement 1.3

    func testSaveDailyGoalOutOfRangeSetsError() {
        let (store, suiteName) = makeStore()
        defer { cleanup(suiteName: suiteName) }

        // Capture the goal before the invalid save attempt
        let goalBefore = store.dailyGoal

        // Attempt to save a value below the minimum (100 ml)
        let accepted = store.setDailyGoal(50)

        // The store should reject the value (equivalent to WaterStore setting goalError)
        XCTAssertFalse(accepted,
                       "setDailyGoal(50) should return false — value is below minimum 100 ml")

        // dailyGoal must remain unchanged (WaterStore only updates dailyGoal on success)
        XCTAssertEqual(store.dailyGoal, goalBefore,
                       "dailyGoal must not change after an out-of-range save attempt")
    }

    // MARK: - Test 2: saveDailyGoal valid clears error and sets dailyGoal
    //
    // WaterStore.saveDailyGoal(1500) should clear goalError and set dailyGoal == 1500.
    // Validates: Requirement 1.2

    func testSaveDailyGoalValidClearsError() {
        let (store, suiteName) = makeStore()
        defer { cleanup(suiteName: suiteName) }

        // Save a valid goal value
        let accepted = store.setDailyGoal(1500)

        // The store should accept the value (equivalent to WaterStore clearing goalError)
        XCTAssertTrue(accepted,
                      "setDailyGoal(1500) should return true — value is within 100–10 000 ml")

        // dailyGoal must reflect the new value
        XCTAssertEqual(store.dailyGoal, 1500,
                       "dailyGoal should be 1500 after a successful save")
    }

    // MARK: - Test 3: saveDefaultPortion out of range sets error and does not change defaultPortion
    //
    // WaterStore.saveDefaultPortion(5) should set portionError != nil and leave defaultPortion unchanged.
    // Validates: Requirement 2.3

    func testSaveDefaultPortionOutOfRangeSetsError() {
        let (store, suiteName) = makeStore()
        defer { cleanup(suiteName: suiteName) }

        // Capture the portion before the invalid save attempt
        let portionBefore = store.defaultPortion

        // Attempt to save a value below the minimum (10 ml)
        let accepted = store.setDefaultPortion(5)

        // The store should reject the value (equivalent to WaterStore setting portionError)
        XCTAssertFalse(accepted,
                       "setDefaultPortion(5) should return false — value is below minimum 10 ml")

        // defaultPortion must remain unchanged
        XCTAssertEqual(store.defaultPortion, portionBefore,
                       "defaultPortion must not change after an out-of-range save attempt")
    }

    // MARK: - Test 4: saveDefaultPortion valid clears error and sets defaultPortion
    //
    // WaterStore.saveDefaultPortion(300) should clear portionError and set defaultPortion == 300.
    // Validates: Requirement 2.2

    func testSaveDefaultPortionValidClearsError() {
        let (store, suiteName) = makeStore()
        defer { cleanup(suiteName: suiteName) }

        // Save a valid portion value
        let accepted = store.setDefaultPortion(300)

        // The store should accept the value (equivalent to WaterStore clearing portionError)
        XCTAssertTrue(accepted,
                      "setDefaultPortion(300) should return true — value is within 10–2 000 ml")

        // defaultPortion must reflect the new value
        XCTAssertEqual(store.defaultPortion, 300,
                       "defaultPortion should be 300 after a successful save")
    }

    // MARK: - Test 5: addPortion increases dailyIntake by the given amount
    //
    // WaterStore.addPortion(250) should increase dailyIntake by 250.
    // Validates: Requirements 3.3, 4.5

    func testAddPortionIncreasesIntake() {
        let (store, suiteName) = makeStore()
        defer { cleanup(suiteName: suiteName) }

        let intakeBefore = store.dailyIntake
        XCTAssertEqual(intakeBefore, 0, "Precondition: fresh store should have dailyIntake == 0")

        store.addPortion(250)

        XCTAssertEqual(store.dailyIntake, intakeBefore + 250,
                       "dailyIntake should increase by exactly 250 after addPortion(250)")
    }

    // MARK: - Test 6: progress is clamped to 1.0 when dailyIntake > dailyGoal
    //
    // WaterStore.progress should return 1.0 when intake exceeds goal.
    // Validates: Requirement 3.4

    func testProgressIsClampedToOne() {
        let (store, suiteName) = makeStore()
        defer { cleanup(suiteName: suiteName) }

        // Set a goal of 500 ml, then add 600 ml (exceeds goal)
        store.setDailyGoal(500)
        store.addPortion(600)

        let progress = computeProgress(intake: store.dailyIntake, goal: store.dailyGoal)

        XCTAssertEqual(progress, 1.0, accuracy: 1e-9,
                       "progress should be clamped to 1.0 when dailyIntake (\(store.dailyIntake)) > dailyGoal (\(store.dailyGoal))")
    }

    // MARK: - Test 7: progress is 0.0 when dailyIntake == 0
    //
    // WaterStore.progress should return 0.0 when no water has been logged.
    // Validates: Requirement 3.3

    func testProgressIsZeroWhenNoIntake() {
        let (store, suiteName) = makeStore()
        defer { cleanup(suiteName: suiteName) }

        // Fresh store: dailyIntake == 0
        XCTAssertEqual(store.dailyIntake, 0, "Precondition: fresh store should have dailyIntake == 0")

        let progress = computeProgress(intake: store.dailyIntake, goal: store.dailyGoal)

        XCTAssertEqual(progress, 0.0, accuracy: 1e-9,
                       "progress should be 0.0 when dailyIntake is 0")
    }
}
