import XCTest
@testable import Autopilot

final class DomainValueTests: XCTestCase {
    func testDueDateRoundTripsThroughCodable() throws {
        let due = DueDate.timed(date: .now, time: .now.addingTimeInterval(3600))
        let data = try JSONEncoder().encode(due)
        let decoded = try JSONDecoder().decode(DueDate.self, from: data)
        XCTAssertEqual(decoded, due)
    }

    func testActionRoundTripsThroughCodable() throws {
        let action = Action(
            title: "Email professor about exam",
            kind: .task,
            category: ActionCategory.university.rawValue,
            priority: .high,
            due: DueDate.day(.now),
            estimateMinutes: 30,
            reminder: ReminderRule(offsets: ReminderRule.defaultOffsets, isEnabled: true),
            sourceQuote: "email professor",
            confidence: 0.92
        )
        let data = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(Action.self, from: data)
        XCTAssertEqual(decoded, action)
    }

    func testCategoryNormalizationFallsBackToOther() {
        XCTAssertEqual(ActionCategory.normalized("Finance"), .finance)
        XCTAssertEqual(ActionCategory.normalized("unknown-tag"), .other)
    }

    func testPriorityOrderingIsComparable() {
        XCTAssertLessThan(Priority.low, Priority.high)
        XCTAssertEqual(Priority.allCases.first, .low)
        XCTAssertEqual(Priority.allCases.last, .high)
    }

    func testOverdueDetectsOpenActionFromPreviousDay() {
        var action = Action(title: "Pay internet bill")
        action.due = DueDate.day(Calendar.current.date(byAdding: .day, value: -1, to: .now)!)
        XCTAssertTrue(action.isOverdue())

        action.status = .done
        action.completedAt = .now
        XCTAssertFalse(action.isOverdue())
    }

    func testReminderDefaultsFollowThe26HourRule() {
        let soon = Date.now.addingTimeInterval(2 * 3600)
        XCTAssertEqual(ReminderRule.defaults(forDue: soon, relativeTo: .now).offsets, ReminderRule.sameDayOffsets)

        let far = Date.now.addingTimeInterval(3 * 86_400)
        XCTAssertEqual(ReminderRule.defaults(forDue: far, relativeTo: .now).offsets, ReminderRule.defaultOffsets)
    }
}
