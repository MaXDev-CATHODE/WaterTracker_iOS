// WaterLogicPropertyTests.swift — Property-based tests for WaterLogic pure functions
//
// Uses SwiftCheck to verify universal properties across randomly generated inputs.
// Each property corresponds to a correctness property defined in the design document.

import XCTest
import SwiftCheck
@testable import WaterTrackerShared

final class WaterLogicPropertyTests: XCTestCase {

    // MARK: - Property 1: DailyGoal range validation
    // Feature: water-tracker-ios, Property 1: DailyGoal range validation

    /// Validates: Requirements 1.1, 1.3
    func testDailyGoalValidation() {
        property("isValidDailyGoal returns true iff value is in [100, 10000]") <- forAll { (value: Int) in
            let result = isValidDailyGoal(value)
            let expected = value >= 100 && value <= 10_000
            return result == expected
        }
    }

    // MARK: - Property 2: Portion range validation
    // Feature: water-tracker-ios, Property 2: Portion range validation

    /// Validates: Requirements 2.1, 2.3, 4.4
    func testPortionValidation() {
        property("isValidPortion returns true iff value is in [10, 2000]") <- forAll { (value: Int) in
            let result = isValidPortion(value)
            let expected = value >= 10 && value <= 2_000
            return result == expected
        }
    }

    // MARK: - Property 6: Progress ratio range and proportionality
    // Feature: water-tracker-ios, Property 6: Progress calculation

    /// Validates: Requirements 3.3, 3.4
    func testProgressRangeAndProportionality() {
        property("computeProgress is in [0.0, 1.0] and proportional to intake/goal") <- forAll(
            Gen<Int>.choose((0, 50_000)),  // intake >= 0
            Gen<Int>.choose((1, 10_000))   // goal > 0 (avoids division by zero)
        ) { intake, goal in
            let p = computeProgress(intake: intake, goal: goal)

            // Must always be within [0.0, 1.0]
            let inRange = p >= 0.0 && p <= 1.0

            // When intake < goal: result must equal exact ratio
            // When intake >= goal: result must be clamped to 1.0
            let proportional: Bool
            if intake < goal {
                proportional = abs(p - Double(intake) / Double(goal)) < 1e-9
            } else {
                proportional = p == 1.0
            }

            return inRange && proportional
        }
    }

    // MARK: - Property 7: Subtraction floors at zero (non-negativity)
    // Feature: water-tracker-ios, Property 7: Subtraction never goes below zero

    /// Validates: Requirements 4.6, 4.7
    func testSubtractionNeverNegative() {
        property("applySubtraction always returns a value >= 0") <- forAll(
            Gen<Int>.choose((0, 10_000)),  // intake >= 0
            Gen<Int>.choose((0, 10_000))   // portion >= 0
        ) { intake, portion in
            let result = applySubtraction(intake: intake, portion: portion)
            return result >= 0
        }
    }

    // Feature: water-tracker-ios, Property 7: Subtraction equals max(0, intake - portion)

    /// Validates: Requirements 4.6, 4.7
    func testSubtractionEqualsMaxZero() {
        property("applySubtraction equals max(0, intake - portion) for all inputs") <- forAll(
            Gen<Int>.choose((0, 10_000)),  // intake >= 0
            Gen<Int>.choose((0, 10_000))   // portion >= 0
        ) { intake, portion in
            applySubtraction(intake: intake, portion: portion) == max(0, intake - portion)
        }
    }
}
