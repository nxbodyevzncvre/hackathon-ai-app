import Foundation

/// Reminder offsets relative to the due instant, in seconds.
struct ReminderRule: Codable, Hashable {
    var offsets: [TimeInterval] = []
    var isEnabled: Bool = true

    /// Default reminders for explicit deadlines more than 26h away.
    static let defaultOffsets: [TimeInterval] = [-86_400, -3_600]
    /// Default reminders for deadlines inside the next 26h.
    static let sameDayOffsets: [TimeInterval] = [-3_600]

    /// Per the AI contract: explicit deadline >26h out gets 24h + 1h.
    static func defaults(forDue instant: Date, relativeTo now: Date) -> ReminderRule {
        let horizon: TimeInterval = 26 * 3600
        let offsets = instant.timeIntervalSince(now) > horizon
            ? defaultOffsets
            : sameDayOffsets
        return ReminderRule(offsets: offsets, isEnabled: true)
    }
}
