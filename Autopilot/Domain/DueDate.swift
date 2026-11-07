import Foundation

/// A due date with explicit precision. `isExplicit == false` means the user
/// never stated a date (model or system suggested it).
struct DueDate: Codable, Hashable {
    enum Precision: String, Codable, CaseIterable, Hashable {
        case day, time, unknown
    }

    /// Date component only; hours/minutes are calendar start-of-day.
    var date: Date
    /// Optional absolute time-of-day instant.
    var time: Date?
    var precision: Precision
    var isExplicit: Bool

    static func day(_ date: Date, isExplicit: Bool = true) -> DueDate {
        DueDate(date: date, time: nil, precision: .day, isExplicit: isExplicit)
    }

    static func timed(date: Date, time: Date, isExplicit: Bool = true) -> DueDate {
        DueDate(date: date, time: time, precision: .time, isExplicit: isExplicit)
    }

    /// The concrete instant reminders anchor to; falls back to day start.
    var instant: Date { time ?? date }
}

extension DueDate {
    /// Human label like "Tomorrow", "Fri, Nov 13", or "Fri, Nov 13, 09:00".
    var displayLabel: String {
        guard isExplicit else { return "No date yet" }
        let dayFormatter = DateFormatter()
        dayFormatter.dateStyle = .medium
        dayFormatter.doesRelativeDateFormatting = true
        dayFormatter.timeStyle = .none
        let day = dayFormatter.string(from: date)
        guard let time else { return day }
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        return "\(day), \(timeFormatter.string(from: time))"
    }
}
