import Foundation

/// One-tap date shortcuts in the editor.
enum QuickDate: String, CaseIterable, Identifiable {
    case today, tomorrow, weekend, nextWeek

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .tomorrow: "Tomorrow"
        case .weekend: "Weekend"
        case .nextWeek: "Next Week"
        }
    }

    var symbol: String {
        switch self {
        case .today: "sun.max"
        case .tomorrow: "sunrise"
        case .weekend: "sofa"
        case .nextWeek: "calendar.badge.clock"
        }
    }

    /// The start of the day this shortcut refers to.
    func day(from now: Date, calendar: Calendar = .current) -> Date {
        let today = calendar.startOfDay(for: now)
        func adding(_ days: Int) -> Date { calendar.date(byAdding: .day, value: days, to: today) ?? today }

        switch self {
        case .today:
            return today
        case .tomorrow:
            return adding(1)
        case .weekend:
            // Saturday, or today if it's already the weekend.
            if calendar.isDateInWeekend(today) { return today }
            return calendar.nextDate(after: today, matching: DateComponents(weekday: 7), matchingPolicy: .nextTime) ?? adding(1)
        case .nextWeek:
            return calendar.nextDate(after: today, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime) ?? adding(7)
        }
    }

    /// The shortcut matching `date`, if any.
    static func matching(_ date: Date, now: Date, calendar: Calendar = .current) -> QuickDate? {
        allCases.first { calendar.isDate($0.day(from: now, calendar: calendar), inSameDayAs: date) }
    }
}
