import Foundation
import SwiftData

@Model
final class Reminder {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    /// The day (and, when `hasTime` is true, the time) the reminder is due.
    /// `nil` means "no specific date", which lives in Today.
    var dueDate: Date?
    var hasTime: Bool = false
    var isCompleted: Bool = false
    var completedAt: Date?
    var createdAt: Date = Date.now
    /// Set when the user interacts with a notification for this reminder.
    /// Once acknowledged, the current alert stops re-reminding.
    var acknowledgedAt: Date?
    /// When set, replaces the due date as the alert time.
    var snoozedUntil: Date?

    init(title: String, notes: String = "", dueDate: Date? = nil, hasTime: Bool = false) {
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.hasTime = dueDate == nil ? false : hasTime
    }
}

extension Reminder {
    func bucket(now: Date = .now, calendar: Calendar = .current) -> ReminderBucket {
        ReminderBucket.bucket(for: dueDate, now: now, calendar: calendar)
    }

    /// When the first notification for this reminder fires, or `nil` if it shouldn't notify.
    func alertDate(allDayMinutes: Int = AppSettings.allDayAlertMinutes, calendar: Calendar = .current) -> Date? {
        if let snoozedUntil { return snoozedUntil }
        guard let dueDate else { return nil }
        return Self.alertDate(for: dueDate, hasTime: hasTime, allDayMinutes: allDayMinutes, calendar: calendar)
    }

    static func alertDate(for due: Date, hasTime: Bool, allDayMinutes: Int, calendar: Calendar) -> Date {
        if hasTime { return due }
        let startOfDay = calendar.startOfDay(for: due)
        return calendar.date(byAdding: .minute, value: allDayMinutes, to: startOfDay) ?? startOfDay
    }

    /// Changes the due date and restarts the alert cycle. Setting a date whose alert
    /// is already in the past doesn't start nagging: the user just chose it.
    func setDue(_ date: Date?, hasTime: Bool, now: Date = .now, calendar: Calendar = .current) {
        dueDate = date
        self.hasTime = date == nil ? false : hasTime
        snoozedUntil = nil
        acknowledgedAt = nil
        if let alert = alertDate(calendar: calendar), alert <= now {
            acknowledgedAt = now
        }
    }

    /// Moves the reminder to `offset` days from today, keeping its time of day.
    func moveToDay(offset: Int, now: Date = .now, calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: now)
        guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { return }
        if hasTime, let dueDate {
            setDue(calendar.combine(day: day, time: dueDate), hasTime: true, now: now, calendar: calendar)
        } else {
            setDue(day, hasTime: false, now: now, calendar: calendar)
        }
    }

    func snooze(for interval: TimeInterval, now: Date = .now) {
        snoozedUntil = now.addingTimeInterval(interval)
        acknowledgedAt = nil
    }

    func complete(at date: Date = .now) {
        isCompleted = true
        completedAt = date
        snoozedUntil = nil
    }

    func uncomplete(now: Date = .now) {
        isCompleted = false
        completedAt = nil
        // Don't immediately resume nagging about an alert that already went off.
        acknowledgedAt = now
    }

    func isOverdue(now: Date = .now, calendar: Calendar = .current) -> Bool {
        guard !isCompleted, let dueDate else { return false }
        if hasTime { return dueDate < now }
        return calendar.startOfDay(for: dueDate) < calendar.startOfDay(for: now)
    }

    func isSnoozed(now: Date = .now) -> Bool {
        guard let snoozedUntil else { return false }
        return snoozedUntil > now
    }
}

extension Calendar {
    /// The date on `day` at the hour and minute of `time`.
    func combine(day: Date, time: Date) -> Date {
        let t = dateComponents([.hour, .minute], from: time)
        return date(bySettingHour: t.hour ?? 9, minute: t.minute ?? 0, second: 0, of: day) ?? day
    }

    /// The top of the next hour after `date`.
    func nextHour(after date: Date) -> Date {
        let floored = self.date(from: dateComponents([.year, .month, .day, .hour], from: date)) ?? date
        return self.date(byAdding: .hour, value: 1, to: floored) ?? date
    }
}
