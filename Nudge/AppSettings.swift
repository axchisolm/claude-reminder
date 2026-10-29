import Foundation

/// User preferences, stored in UserDefaults and shared with `@AppStorage`.
enum AppSettings {
    static let nagEnabledKey = "nagEnabled"
    static let nagIntervalKey = "nagIntervalMinutes"
    static let allDayAlertMinutesKey = "allDayAlertMinutes"

    static let defaultNagInterval = 15
    static let defaultAllDayAlertMinutes = 9 * 60
    static let nagIntervalChoices = [1, 2, 5, 10, 15, 20, 30, 45, 60, 90, 120]
    static let snoozeInterval: TimeInterval = 60 * 60

    /// How long to wait before re-reminding about an ignored notification, or `nil` if off.
    static var nagInterval: TimeInterval? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: nagEnabledKey) as? Bool ?? true else { return nil }
        let minutes = defaults.object(forKey: nagIntervalKey) as? Int ?? defaultNagInterval
        return TimeInterval(max(1, minutes) * 60)
    }

    /// Minutes after midnight that dated reminders without a time notify.
    static var allDayAlertMinutes: Int {
        UserDefaults.standard.object(forKey: allDayAlertMinutesKey) as? Int ?? defaultAllDayAlertMinutes
    }

    static func intervalText(minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60, rest = minutes % 60
        return rest == 0 ? "\(hours) hr" : "\(hours) hr \(rest) min"
    }
}
