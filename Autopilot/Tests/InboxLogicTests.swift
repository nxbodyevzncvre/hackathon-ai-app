import Foundation
import XCTest
@testable import Autopilot

/// Pure grouping, filtering and summary logic of the Inbox screen.
final class InboxLogicTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Bratislava") ?? .current
        return calendar
    }

    private var now: Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 11
        components.day = 7 // a Saturday
        return calendar.date(from: components) ?? .now
    }

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)) ?? now
    }

    private func action(
        _ title: String,
        status: ActionStatus = .planned,
        due: DueDate? = nil,
        category: ActionCategory = .personal
    ) -> Action {
        var model = Action(title: title, category: category.rawValue)
        model.status = status
        model.due = due
        if status == .done { model.completedAt = day(-1) }
        return model
    }

    // MARK: - Grouping

    func testSectionsAreUnsortedFirstAndSkipEmptyGroups() {
        let actions = [
            action("Later project", status: .planned, due: DueDate.day(day(5))),
            action("Forgot to sort this", status: .inbox),
            action("Late library return", status: .planned, due: DueDate.day(day(-1))),
            action("Today's email", status: .planned, due: DueDate.day(day(0))),
            action("Tomorrow's gift", status: .planned, due: DueDate.day(day(1))),
            action("Done lab report", status: .done),
        ]

        let sections = InboxViewModel.sections(for: actions, now: now, calendar: calendar)

        let titles = sections.map(\.title)
        XCTAssertEqual(titles, ["Unsorted", "Overdue", "Today", "Tomorrow", "Later", "Done"])

        XCTAssertEqual(sections[0].actions.map(\.title), ["Forgot to sort this"])
        XCTAssertEqual(sections[1].actions.map(\.title), ["Late library return"])
        XCTAssertEqual(sections[2].actions.map(\.title), ["Today's email"])
        XCTAssertEqual(sections[3].actions.map(\.title), ["Tomorrow's gift"])
        XCTAssertEqual(sections[4].actions.map(\.title), ["Later project"])
        XCTAssertEqual(sections[5].actions.map(\.title), ["Done lab report"])
    }

    // MARK: - Category filter

    func testCategoryFilterKeepsAllWhenUnselected() {
        let actions = [
            action("One", category: .work),
            action("Two", category: .health),
        ]
        let filtered = InboxViewModel.filter(actions, categoryTitleIndex: 0)
        XCTAssertEqual(filtered.count, 2)
    }

    func testCategoryFilterSelectsOnlyMatchingCategory() {
        let actions = [
            action("Email", category: .university),
            action("Invoice", category: .work),
            action("Invoice again", category: .work),
            action("Dentist", category: .health),
        ]
        let workIndex = InboxViewModel.categoryTitles.firstIndex(of: "Work") ?? 0
        let filtered = InboxViewModel.filter(actions, categoryTitleIndex: workIndex)
        XCTAssertEqual(filtered.map(\.title), ["Invoice", "Invoice again"])
    }

    // MARK: - Weekly summary

    func testWeeklySummaryCountsDoneAndOpen() {
        var stale = action("Old done", status: .done)
        stale.completedAt = day(-14) // previous week, excluded
        let actions = [
            stale,
            action("This week done", status: .done),
            action("Open one", status: .planned, due: DueDate.day(day(1))),
            action("Unsorted two", status: .inbox),
        ]

        let summary = InboxViewModel.weeklySummary(for: actions, now: now, calendar: calendar)
        XCTAssertEqual(summary.completedCount, 1)
        XCTAssertEqual(summary.openCount, 2)
    }

    // MARK: - Today screen feed

    func testTodayShowsOverdueAndTodayOnly() {
        let actions = [
            action("Tomorrow thing", due: DueDate.day(day(1))),
            action("Today thing", due: DueDate.day(day(0))),
            action("Yesterday thing", due: DueDate.day(day(-1))),
            action("Someday thing"),
        ]

        let today = TodayScreen.sections(for: actions, now: now, calendar: calendar)

        XCTAssertEqual(today.overdue.map(\.title), ["Yesterday thing"])
        XCTAssertEqual(today.dueToday.map(\.title), ["Today thing"])
        XCTAssertEqual(today.openCount, 4)
    }
}
