import Foundation

/// Domain value types. Views see these, never `@Model` records.

enum ActionKind: String, Codable, CaseIterable, Hashable {
    case task, event, reminder, note, payment

    var displayName: String {
        switch self {
        case .task: "Task"
        case .event: "Event"
        case .reminder: "Reminder"
        case .note: "Note"
        case .payment: "Payment"
        }
    }

    var symbolName: String {
        switch self {
        case .task: "checkmark.circle"
        case .event: "calendar"
        case .reminder: "bell"
        case .note: "note.text"
        case .payment: "creditcard"
        }
    }
}

enum ActionStatus: String, Codable, CaseIterable, Hashable {
    case inbox, planned, done, cancelled
}

enum Priority: Int, Codable, CaseIterable, Hashable, Comparable {
    case low = 0, normal = 1, high = 2

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .low: "Low"
        case .normal: "Normal"
        case .high: "High"
        }
    }

    /// Icon + text so priority is never communicated by color alone.
    var symbolName: String? {
        switch self {
        case .low: "arrow.down"
        case .normal: nil
        case .high: "exclamationmark.2"
        }
    }
}

struct Action: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var title: String
    var notes: String = ""
    var kind: ActionKind = .task
    var category: String = ActionCategory.other.rawValue
    var priority: Priority = .normal
    var due: DueDate? = nil
    var status: ActionStatus = .inbox
    var estimateMinutes: Int? = nil
    var reminder: ReminderRule = ReminderRule()
    var sourceQuote: String = ""
    var confidence: Double = 1.0
    var createdAt: Date = .now
    var completedAt: Date? = nil
}

extension Action {
    var categoryKind: ActionCategory {
        ActionCategory(rawValue: category) ?? .other
    }

    var isDone: Bool { status == .done }

    /// Overdue means: has a date, still open, and the date is behind now.
    func isOverdue(now: Date = .now, calendar: Calendar = .current) -> Bool {
        guard !isDone, status != .cancelled, let due else { return false }
        return due.date < calendar.startOfDay(for: now)
    }

    var estimateLabel: String? {
        guard let estimateMinutes else { return nil }
        let hours = estimateMinutes / 60
        let minutes = estimateMinutes % 60
        if hours > 0 && minutes == 0 { return "\(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}
