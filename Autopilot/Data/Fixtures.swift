import Foundation

/// Realistic debug fixtures (M1 DoD) used for offline demos and previews.
/// All dates are computed relative to `now` so the pile always looks live.
enum Fixtures {
    static func all(now: Date = .now, calendar: Calendar = .current) -> [Action] {
        func day(_ offset: Int) -> Date {
            calendar.date(
                byAdding: .day,
                value: offset,
                to: calendar.startOfDay(for: now)
            ) ?? now
        }

        var friday = day(1)
        while calendar.component(.weekday, from: friday) != 6 {
            friday = calendar.date(byAdding: .day, value: 1, to: friday) ?? friday
        }

        var books = Action(
            title: "Return library books",
            category: ActionCategory.admin.rawValue,
            priority: .high,
            due: DueDate.day(day(-1)),
            estimateMinutes: 15,
            sourceQuote: "you still have my books"
        )
        books.notes = "Fees start applying after midnight."

        var professor = Action(
            title: "Email professor about the exam",
            category: ActionCategory.university.rawValue,
            priority: .high,
            due: DueDate.day(day(0)),
            estimateMinutes: 30,
            sourceQuote: "email my professor about the exam"
        )
        professor.status = .planned

        var bill = Action(
            title: "Pay internet bill",
            kind: .payment,
            category: ActionCategory.finance.rawValue,
            due: DueDate.day(friday),
            estimateMinutes: 10,
            reminder: ReminderRule.defaults(forDue: friday, relativeTo: now),
            sourceQuote: "you have to pay by Friday"
        )
        bill.status = .planned
        bill.notes = "Bank transfer, reference on the paper bill."

        var dentist = Action(
            title: "Dentist appointment",
            kind: .event,
            category: ActionCategory.health.rawValue,
            priority: .normal,
            due: DueDate(
                date: calendar.startOfDay(for: friday),
                time: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: friday) ?? friday,
                precision: .time,
                isExplicit: true
            ),
            estimateMinutes: 60
        )
        dentist.status = .planned

        var project = Action(
            title: "Finish the university project",
            category: ActionCategory.university.rawValue,
            priority: .low,
            due: DueDate.day(day(10)),
            estimateMinutes: 240,
            sourceQuote: "next week I need to finish my university project"
        )
        project.confidence = 0.6
        project.status = .planned

        let laundry = Action(
            title: "Sort out laundry pickup",
            category: ActionCategory.personal.rawValue
        )

        var gift = Action(
            title: "Buy a birthday gift for Masha",
            category: ActionCategory.personal.rawValue,
            due: DueDate.day(day(1)),
            estimateMinutes: 60
        )
        gift.status = .planned

        var lab = Action(
            title: "Submit the lab report",
            category: ActionCategory.university.rawValue,
            priority: .high,
            due: DueDate.day(day(-2)),
            estimateMinutes: 45
        )
        lab.status = .done
        lab.completedAt = day(-1)

        return [books, professor, bill, dentist, project, laundry, gift, lab]
    }
}

/// Seeds the eight debug fixtures exactly once, on the first empty launch.
@MainActor
enum FixtureSeeder {
    /// Returns true when seeding happened; false when data already exists.
    static func seedIfNeeded(
        in repository: ActionRepository,
        fixtures: [Action]
    ) throws -> Bool {
        guard try repository.isEmpty() else { return false }
        for fixture in fixtures {
            try repository.create(fixture)
        }
        return true
    }
}
