import Foundation

/// Observable user settings, persisted in UserDefaults. Fields match the
/// AI contract and planning algorithm (§6 of the brief). Times are stored
/// as minutes-of-day so planning math needs no date conversion.
@MainActor
@Observable
final class SettingsStore {
    static let workdayStartDefault = 540 // 09:00
    static let workdayEndDefault = 1020 // 17:00
    static let capacityDefault = 180 // minutes
    static let briefingDefault = 480 // 08:00
    static let quietStartDefault = 1320 // 22:00
    static let quietEndDefault = 480 // 08:00

    var workdayStartMinutes: Int
    var workdayEndMinutes: Int
    var dailyCapacityMinutes: Int
    var briefingMinutes: Int
    var notificationsEnabled: Bool
    var quietStartMinutes: Int
    var quietEndMinutes: Int

    let timeZone: TimeZone

    private let defaults: UserDefaults

    private enum Key {
        static let workdayStart = "settings.workdayStartMinutes"
        static let workdayEnd = "settings.workdayEndMinutes"
        static let capacity = "settings.dailyCapacityMinutes"
        static let briefing = "settings.briefingMinutes"
        static let notifications = "settings.notificationsEnabled"
        static let quietStart = "settings.quietStartMinutes"
        static let quietEnd = "settings.quietEndMinutes"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        workdayStartMinutes = defaults.integer(forKey: Key.workdayStart, orDefault: Self.workdayStartDefault)
        workdayEndMinutes = defaults.integer(forKey: Key.workdayEnd, orDefault: Self.workdayEndDefault)
        dailyCapacityMinutes = defaults.integer(forKey: Key.capacity, orDefault: Self.capacityDefault)
        briefingMinutes = defaults.integer(forKey: Key.briefing, orDefault: Self.briefingDefault)
        notificationsEnabled = defaults.bool(forKey: Key.notifications)
        quietStartMinutes = defaults.integer(forKey: Key.quietStart, orDefault: Self.quietStartDefault)
        quietEndMinutes = defaults.integer(forKey: Key.quietEnd, orDefault: Self.quietEndDefault)
        timeZone = TimeZone.current
    }

    func persist() {
        defaults.set(workdayStartMinutes, forKey: Key.workdayStart)
        defaults.set(workdayEndMinutes, forKey: Key.workdayEnd)
        defaults.set(dailyCapacityMinutes, forKey: Key.capacity)
        defaults.set(briefingMinutes, forKey: Key.briefing)
        defaults.set(notificationsEnabled, forKey: Key.notifications)
        defaults.set(quietStartMinutes, forKey: Key.quietStart)
        defaults.set(quietEndMinutes, forKey: Key.quietEnd)
    }

    // MARK: - Minute-of-day <-> Date conversion

    nonisolated static func date(forMinutes minutes: Int, calendar: Calendar = .current) -> Date {
        calendar
            .startOfDay(for: .now)
            .addingTimeInterval(TimeInterval(minutes) * 60)
    }

    nonisolated static func minutes(from date: Date, calendar: Calendar = .current) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}

private extension UserDefaults {
    func integer(forKey key: String, orDefault fallback: Int) -> Int {
        object(forKey: key) as? Int ?? fallback
    }
}
