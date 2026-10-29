import Foundation

/// Short, human due-date labels: "3:00 PM", "Tomorrow, 9:30 AM", "Tuesday", "Nov 12".
enum DueFormatter {
    static func label(due: Date, hasTime: Bool, now: Date = .now, calendar: Calendar = .current) -> String {
        let today = calendar.startOfDay(for: now)
        let day = calendar.startOfDay(for: due)
        let dayOffset = calendar.dateComponents([.day], from: today, to: day).day ?? 0
        let time = due.formatted(date: .omitted, time: .shortened)

        let dayText: String
        switch dayOffset {
        case 0:
            if hasTime { return time }
            dayText = "Today"
        case 1:
            dayText = "Tomorrow"
        case -1:
            dayText = "Yesterday"
        case 2...6:
            dayText = due.formatted(.dateTime.weekday(.wide))
        default:
            if calendar.isDate(due, equalTo: now, toGranularity: .year) {
                dayText = due.formatted(.dateTime.month(.abbreviated).day())
            } else {
                dayText = due.formatted(.dateTime.month(.abbreviated).day().year())
            }
        }
        return hasTime ? "\(dayText), \(time)" : dayText
    }
}
