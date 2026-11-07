import Foundation
import SwiftData
import XCTest
@testable import Autopilot

@MainActor
final class RepositoryTests: XCTestCase {
    // MARK: - Relaunch simulation: a repository opened again over the same
    // on-disk store must see every mutation from the "previous launch".

    private var tempDirectoryURL: URL!

    override func setUpWithError() throws {
        tempDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("repo-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectoryURL)
    }

    private func makeRepository() throws -> ActionRepository {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            url: tempDirectoryURL.appendingPathComponent("store.sqlite")
        )
        let container = try ModelContainer(
            for: schema,
            migrationPlan: AutopilotMigrationPlan.self,
            configurations: [configuration]
        )
        return ActionRepository(container: container)
    }

    private var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now))
            ?? .now
    }

    func testCreateSurvivesRelaunch() throws {
        let firstLaunch = try makeRepository()
        let action = Action(
            title: "Email professor about exam",
            category: ActionCategory.university.rawValue,
            due: DueDate.day(tomorrow),
            estimateMinutes: 30,
            reminder: ReminderRule(offsets: ReminderRule.defaultOffsets, isEnabled: true),
            sourceQuote: "email my professor",
            confidence: 0.9
        )
        try firstLaunch.create(action)

        XCTAssertEqual(try firstLaunch.count(), 1)

        let secondLaunch = try makeRepository()
        let loaded = try XCTUnwrap(try secondLaunch.action(id: action.id))
        XCTAssertEqual(loaded.title, "Email professor about exam")
        XCTAssertEqual(loaded.categoryKind, .university)
        XCTAssertEqual(loaded.due?.date, tomorrow)
        XCTAssertEqual(loaded.due?.precision, .day)
        XCTAssertEqual(loaded.estimateMinutes, 30)
        XCTAssertEqual(loaded.reminder.offsets, ReminderRule.defaultOffsets)
        XCTAssertTrue(loaded.reminder.isEnabled)
        XCTAssertEqual(loaded.sourceQuote, "email my professor")
    }

    func testEditAndCompleteSurviveRelaunch() throws {
        let firstLaunch = try makeRepository()
        var action = Action(title: "Pay internet bill", category: ActionCategory.finance.rawValue)
        action.kind = .payment
        try firstLaunch.create(action)

        let secondLaunch = try makeRepository()
        var loaded = try XCTUnwrap(try secondLaunch.action(id: action.id))
        loaded.title = "Pay internet bill before migration"
        loaded.priority = .high
        loaded.status = .done
        loaded.completedAt = .now
        try secondLaunch.update(loaded)

        let thirdLaunch = try makeRepository()
        let after = try XCTUnwrap(try thirdLaunch.action(id: action.id))
        XCTAssertEqual(after.title, "Pay internet bill before migration")
        XCTAssertEqual(after.priority, .high)
        XCTAssertEqual(after.status, .done)
        XCTAssertNotNil(after.completedAt)
    }

    func testDeleteSurvivesRelaunch() throws {
        let firstLaunch = try makeRepository()
        let action = Action(title: "Sort laundry pickup")
        try firstLaunch.create(action)

        let secondLaunch = try makeRepository()
        try secondLaunch.delete(id: action.id)
        XCTAssertTrue(try secondLaunch.isEmpty())

        let thirdLaunch = try makeRepository()
        XCTAssertNil(try thirdLaunch.action(id: action.id))
    }

    func testUpdateWithoutExistingRecordIsANoopNotACrash() throws {
        let repository = try makeRepository()
        try repository.update(Action(title: "Ghost"))
        XCTAssertTrue(try repository.isEmpty())
    }
}
