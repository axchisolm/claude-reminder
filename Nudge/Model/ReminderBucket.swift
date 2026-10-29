import Foundation

/// The three sections of the main list.
enum ReminderBucket: String, CaseIterable, Identifiable {
    /// No date, due today, or overdue.
    case today
    /// Tomorrow through the next seven days.
    case thisWeek
    /// Everything after that.
    case later

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .thisWeek: "This Week"
        case .later: "Later"
        }
    }

    static func bucket(for due: Date?, now: Date, calendar: Calendar) -> ReminderBucket {
        guard let due else { return .today }
        let today = calendar.startOfDay(for: now)
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today),
              let weekEnd = calendar.date(byAdding: .day, value: 8, to: today)
        else { return .today }

        if due < tomorrow { return .today }
        if due < weekEnd { return .thisWeek }
        return .later
    }
}
