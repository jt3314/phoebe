import XCTest
@testable import EnergyTodo

final class EffortCalculatorTests: XCTestCase {

    // MARK: - Default Effort Pattern

    func testDay1IsRest() {
        XCTAssertEqual(EffortCalculator.getDefaultEffortForCycleDay(1), 0)
    }

    func testDay2IsLow() {
        XCTAssertEqual(EffortCalculator.getDefaultEffortForCycleDay(2), 2)
    }

    func testDay13IsPeak() {
        XCTAssertEqual(EffortCalculator.getDefaultEffortForCycleDay(13), 15)
    }

    func testDay15IsPeak() {
        XCTAssertEqual(EffortCalculator.getDefaultEffortForCycleDay(15), 15)
    }

    func testDay35IsLow() {
        XCTAssertEqual(EffortCalculator.getDefaultEffortForCycleDay(35), 5)
    }

    func testDay50DefaultsTo5() {
        XCTAssertEqual(EffortCalculator.getDefaultEffortForCycleDay(50), 5)
    }

    // MARK: - Generate Default Array

    func testGenerateDefaultArrayLength() {
        let array = EffortCalculator.generateDefaultEffortPointsArray(cycleLength: 35)
        XCTAssertEqual(array.count, 35)
        XCTAssertEqual(array[0].dayNumber, 1)
        XCTAssertEqual(array[0].effortPoints, 0)
        XCTAssertEqual(array[34].dayNumber, 35)
    }

    func testGenerateArrayFor7Days() {
        let array = EffortCalculator.generateDefaultEffortPointsArray(cycleLength: 7)
        XCTAssertEqual(array.count, 7)
    }

    // MARK: - Effort Breakdown

    func testEffortBreakdownBasic() {
        let effortMap: [Int: Int] = [1: 0, 2: 2, 3: 4, 4: 4, 5: 4]
        let breakdown = EffortCalculator.getEffortBreakdown(
            date: "2025-01-01",
            day1Date: "2025-01-01",
            cycleLength: 5,
            effortPoints: effortMap
        )
        XCTAssertEqual(breakdown.cycleDay, 1)
        XCTAssertEqual(breakdown.baseEffort, 0)
        XCTAssertEqual(breakdown.totalAvailable, 0)
    }

    func testEffortBreakdownWithSleepReduction() {
        let effortMap: [Int: Int] = [1: 10]
        let sleepCheck = SleepCheck(
            id: UUID(),
            userId: UUID(),
            date: "2025-01-01",
            sleptPoorly: true,
            effortReduction: 3,
            createdAt: Date()
        )
        let breakdown = EffortCalculator.getEffortBreakdown(
            date: "2025-01-01",
            day1Date: "2025-01-01",
            cycleLength: 1,
            effortPoints: effortMap,
            sleepCheck: sleepCheck
        )
        XCTAssertEqual(breakdown.sleepReduction, 3)
        XCTAssertEqual(breakdown.totalAvailable, 7)
    }

    // MARK: - Validation

    func testValidCycleLength() {
        XCTAssertTrue(EffortCalculator.isValidCycleLength(1))
        XCTAssertTrue(EffortCalculator.isValidCycleLength(99))
        XCTAssertFalse(EffortCalculator.isValidCycleLength(0))
        XCTAssertFalse(EffortCalculator.isValidCycleLength(100))
    }

    func testValidEffortPoints() {
        XCTAssertTrue(EffortCalculator.isValidEffortPoints(0))
        XCTAssertTrue(EffortCalculator.isValidEffortPoints(50))
        XCTAssertFalse(EffortCalculator.isValidEffortPoints(-1))
        XCTAssertFalse(EffortCalculator.isValidEffortPoints(51))
    }

    // MARK: - Effort Description

    func testEffortDescriptions() {
        XCTAssertEqual(EffortCalculator.getEffortDescription(cycleDay: 1), "Rest day")
        XCTAssertEqual(EffortCalculator.getEffortDescription(cycleDay: 2), "Low energy")
        XCTAssertEqual(EffortCalculator.getEffortDescription(cycleDay: 13), "Peak energy")
    }
}
