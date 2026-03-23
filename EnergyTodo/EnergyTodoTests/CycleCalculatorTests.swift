import XCTest
@testable import EnergyTodo

final class CycleCalculatorTests: XCTestCase {

    // MARK: - getCycleDay

    func testCycleDayOnDay1() {
        let result = CycleCalculator.getCycleDay(date: "2025-01-01", day1Date: "2025-01-01", cycleLength: 35)
        XCTAssertEqual(result, 1)
    }

    func testCycleDayOnDay2() {
        let result = CycleCalculator.getCycleDay(date: "2025-01-02", day1Date: "2025-01-01", cycleLength: 35)
        XCTAssertEqual(result, 2)
    }

    func testCycleDayOnLastDay() {
        let result = CycleCalculator.getCycleDay(date: "2025-02-04", day1Date: "2025-01-01", cycleLength: 35)
        XCTAssertEqual(result, 35)
    }

    func testCycleDayWrapsAround() {
        // Day 36 should be Day 1 of the next cycle
        let result = CycleCalculator.getCycleDay(date: "2025-02-05", day1Date: "2025-01-01", cycleLength: 35)
        XCTAssertEqual(result, 1)
    }

    func testCycleDayMultipleCyclesElapsed() {
        // 70 days later = 2 full cycles, should be Day 1
        let result = CycleCalculator.getCycleDay(date: "2025-03-12", day1Date: "2025-01-01", cycleLength: 35)
        XCTAssertEqual(result, 1)
    }

    func testCycleDayBeforeDay1() {
        // 1 day before Day 1 should be the last day of the previous cycle
        let result = CycleCalculator.getCycleDay(date: "2024-12-31", day1Date: "2025-01-01", cycleLength: 35)
        XCTAssertEqual(result, 35)
    }

    func testCycleDayWith7DayCycle() {
        let result = CycleCalculator.getCycleDay(date: "2025-01-08", day1Date: "2025-01-01", cycleLength: 7)
        XCTAssertEqual(result, 1) // Exactly 1 week later = new cycle
    }

    // MARK: - isWeekendDay

    func testSaturdayIsWeekend() {
        // 2025-01-04 is a Saturday
        XCTAssertTrue(CycleCalculator.isWeekendDay(date: "2025-01-04"))
    }

    func testSundayIsWeekend() {
        // 2025-01-05 is a Sunday
        XCTAssertTrue(CycleCalculator.isWeekendDay(date: "2025-01-05"))
    }

    func testMondayIsNotWeekend() {
        // 2025-01-06 is a Monday
        XCTAssertFalse(CycleCalculator.isWeekendDay(date: "2025-01-06"))
    }

    // MARK: - getDateForCycleDay

    func testDateForCycleDay1() {
        let result = CycleCalculator.getDateForCycleDay(1, day1Date: "2025-01-01")
        XCTAssertEqual(result, "2025-01-01")
    }

    func testDateForCycleDay10() {
        let result = CycleCalculator.getDateForCycleDay(10, day1Date: "2025-01-01")
        XCTAssertEqual(result, "2025-01-10")
    }

    // MARK: - getCurrentCycleStartDate

    func testCurrentCycleStartDateOnDay1() {
        let result = CycleCalculator.getCurrentCycleStartDate(
            currentDate: "2025-01-01", day1Date: "2025-01-01", cycleLength: 35
        )
        XCTAssertEqual(result, "2025-01-01")
    }

    func testCurrentCycleStartDateMidCycle() {
        let result = CycleCalculator.getCurrentCycleStartDate(
            currentDate: "2025-01-15", day1Date: "2025-01-01", cycleLength: 35
        )
        XCTAssertEqual(result, "2025-01-01")
    }

    func testCurrentCycleStartDateSecondCycle() {
        let result = CycleCalculator.getCurrentCycleStartDate(
            currentDate: "2025-02-06", day1Date: "2025-01-01", cycleLength: 35
        )
        XCTAssertEqual(result, "2025-02-05")
    }
}
