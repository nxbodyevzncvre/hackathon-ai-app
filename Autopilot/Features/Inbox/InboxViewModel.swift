import Foundation
import SwiftUI

/// Weekly numbers shown as a compact strip at the top of Inbox.
struct WeeklySummary: Hashable {
    var completedCount: Int
    var openCount: Int

    static let empty = WeeklySummary(completedCount: 0, openCount: 0)
}

@MainActor
@Observable
final class InboxViewModel {
    enum Section: Int, CaseIterable, Hashable {
        case unsorted, overdue, today, tomorrow, later, noDate, done

        var title: String {
            switch self {
            case .unsorted: "Unsorted"
            case .overdue: "Overdue"
            case .today: "Today"
            case .tomorrow: "Tomorrow"
            case .later: "Later"
            case .noDate: "No date"
            case .done: "Done"
            }
        }
    }

    struct DisplaySection: Hashable, Identifiable {
        let section: Section
        let actions: [Action]
        var id: Section { section }
        var title: String { section.title }
    }

    let repository: ActionRepository

    private(set) var sections: [DisplaySection] = []
    private(set) var weekly: WeeklySummary = .empty
    private(set) var categoryIndex: Int = 0
    private var actions: [Action] = []
    private var statusBeforeDone: [UUID: ActionStatus] = [:]

    init(repository: ActionRepository) {
        self.repository = repository
    }

    // MARK: - Screen state

    /// Sections after applying the selected category chip (0 = All).
    var filteredSections: [DisplaySection] {
        let filtered = Self.filter(actions, categoryTitleIndex: categoryIndex)
        return Self.sections(for: filtered, now: .now, calendar: .current)
    }

    /// Called by the chip filter row.
    func selectCategory(_ index: Int) {
        categoryIndex = index
        sections = Self.sections(for: filteredSource(), now: .now, calendar: .current)
    }

    private func filteredSource() -> [Action] {
        Self.filter(actions, categoryTitleIndex: categoryIndex)
    }

    func reload() {
        let stored = (try? repository.actions()) ?? []
        actions = stored
        sections = Self.sections(for: stored, now: .now, calendar: .current)
        weekly = Self.weeklySummary(for: stored, now: .now, calendar: .current)
    }

    var hasActions: Bool { !actions.isEmpty }

    func toggleDone(_ id: UUID) {
        guard var action = try? repository.action(id: id) else { return }
        if action.status == .done {
            action.status = statusBeforeDone[id] ?? .planned
            action.completedAt = nil
            statusBeforeDone[id] = nil
        } else {
            statusBeforeDone[id] = action.status
            action.status = .done
            action.completedAt = .now
        }
        try? repository.update(action)
        reload()
    }

    func delete(_ id: UUID) {
        try? repository.delete(id: id)
        reload()
    }

    // MARK: - Pure logic (tested, nonisolated)

    nonisolated static let categoryTitles = ["All"] + ActionCategory.fixed.map(\.displayName)

    nonisolated static func filter(_ actions: [Action], categoryTitleIndex: Int) -> [Action] {
        guard categoryTitleIndex > 0 else { return actions }
        let selected = ActionCategory.fixed[categoryTitleIndex - 1]
        return actions.filter { $0.categoryKind == selected }
    }

    /// Unsorted first (the contract), then Overdue, Today, Tomorrow, Later,
    /// No date, Done. Empty sections are omitted; each list is sorted.
    nonisolated static func sections(
        for actions: [Action],
        now: Date,
        calendar: Calendar
    ) -> [DisplaySection] {
        let startToday = calendar.startOfDay(for: now)
        let startTomorrow = calendar.date(byAdding: .day, value: 1, to: startToday) ?? now
        let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: startToday) ?? now

        var buckets: [Section: [Action]] = [:]
        for action in actions {
            let bucket: Section
            if action.status == .done {
                bucket = .done
            } else if action.status == .cancelled {
                continue
            } else if let due = action.due, due.isExplicit {
                // An explicit date drives the section regardless of status:
                // dated items tell the user when to look at them.
                if due.date < startToday {
                    bucket = .overdue
                } else if due.date < startTomorrow {
                    bucket = .today
                } else if due.date < dayAfterTomorrow {
                    bucket = .tomorrow
                } else {
                    bucket = .later
                }
            } else if action.status == .inbox {
                bucket = .unsorted
            } else {
                bucket = .noDate
            }
            buckets[bucket, default: []].append(action)
        }

        let order: [Section] = [.unsorted, .overdue, .today, .tomorrow, .later, .noDate, .done]
        return order.compactMap { section in
            guard var items = buckets[section], !items.isEmpty else { return nil }
            items = sorted(items, section: section, calendar: calendar)
            return DisplaySection(section: section, actions: items)
        }
    }

    /// Overdue floods first; elsewhere priority desc, then due, then title.
    private nonisolated static func sorted(
        _ actions: [Action],
        section: Section,
        calendar: Calendar
    ) -> [Action] {
        actions.sorted { lhs, rhs in
            switch section {
            case .overdue, .done:
                let lhsDate = section == .overdue
                    ? (lhs.due?.date ?? .distantPast)
                    : (lhs.completedAt ?? .distantPast)
                let rhsDate = section == .overdue
                    ? (rhs.due?.date ?? .distantPast)
                    : (rhs.completedAt ?? .distantPast)
                return lhsDate < rhsDate
            default:
                if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
                if let ld = lhs.due?.date, let rd = rhs.due?.date, ld != rd { return ld < rd }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        }
    }

    /// Completed actions this week and the total open pile.
    nonisolated static func weeklySummary(
        for actions: [Action],
        now: Date,
        calendar: Calendar
    ) -> WeeklySummary {
        let week = calendar.dateInterval(of: .weekOfYear, for: now)
        let completed = actions.filter { action in
            guard action.status == .done, let doneAt = action.completedAt else { return false }
            if let week { return week.contains(doneAt) }
            return false
        }.count
        let open = actions.filter { !$0.isDone && $0.status != .cancelled }.count
        return WeeklySummary(completedCount: completed, openCount: open)
    }
}

/// Pure feed logic for the Today screen: what is late and what is due today;
/// the capacity-aware plan arrives with the planning milestone (M4).
enum TodayScreen {
    struct Sections {
        var overdue: [Action]
        var dueToday: [Action]
        var openCount: Int
    }

    static func sections(
        for actions: [Action],
        now: Date,
        calendar: Calendar
    ) -> Sections {
        let inboxSections = InboxViewModel.sections(for: actions, now: now, calendar: calendar)
        let overdue = inboxSections.first { $0.section == .overdue }?.actions ?? []
        let dueToday = inboxSections.first { $0.section == .today }?.actions ?? []
        let open = actions.filter { !$0.isDone && $0.status != .cancelled }.count
        return Sections(overdue: overdue, dueToday: dueToday, openCount: open)
    }
}
