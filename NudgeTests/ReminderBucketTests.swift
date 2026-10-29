import Foundation
import Testing
@testable import Nudge

struct ReminderBucketTests {
    private func bucket(_ due: Date?) -> ReminderBucket {
        ReminderBucket.bucket(for: due, now: thursdayMorning, calendar: utc)
    }

    @Test func undatedRemindersAreToday() {
        #expect(bucket(nil) == .today)
    }

    @Test(arguments: [
        "2026-10-29T00:00:00Z", // start of today
        "2026-10-29T23:59:00Z", // end of today
        "2026-10-29T08:00:00Z", // earlier today
        "2026-10-20T09:00:00Z", // overdue
    ])
    func todayAndOverdue(_ due: String) {
        #expect(bucket(date(due)) == .today)
    }

    @Test(arguments: [
        "2026-10-30T00:00:00Z", // tomorrow
        "2026-11-02T12:00:00Z", // next Monday
        "2026-11-05T23:59:00Z", // seven days out
    ])
    func thisWeek(_ due: String) {
        #expect(bucket(date(due)) == .thisWeek)
    }

    @Test(arguments: [
        "2026-11-06T00:00:00Z", // eight days out
        "2027-03-01T09:00:00Z",
    ])
    func later(_ due: String) {
        #expect(bucket(date(due)) == .later)
    }
}

struct QuickDateTests {
    @Test func shortcutsFromAThursday() {
        #expect(QuickDate.today.day(from: thursdayMorning, calendar: utc) == date("2026-10-29T00:00:00Z"))
        #expect(QuickDate.tomorrow.day(from: thursdayMorning, calendar: utc) == date("2026-10-30T00:00:00Z"))
        #expect(QuickDate.weekend.day(from: thursdayMorning, calendar: utc) == date("2026-10-31T00:00:00Z"))
        #expect(QuickDate.nextWeek.day(from: thursdayMorning, calendar: utc) == date("2026-11-02T00:00:00Z"))
    }

    @Test func weekendIsTodayOnTheWeekend() {
        let sunday = date("2026-11-01T15:00:00Z")
        #expect(QuickDate.weekend.day(from: sunday, calendar: utc) == date("2026-11-01T00:00:00Z"))
        #expect(QuickDate.nextWeek.day(from: sunday, calendar: utc) == date("2026-11-02T00:00:00Z"))
    }

    @Test func matching() {
        #expect(QuickDate.matching(date("2026-10-30T17:00:00Z"), now: thursdayMorning, calendar: utc) == .tomorrow)
        #expect(QuickDate.matching(date("2026-11-04T17:00:00Z"), now: thursdayMorning, calendar: utc) == nil)
    }
}

struct ReminderTests {
    @Test func allDayAlertUsesConfiguredTime() {
        let alert = Reminder.alertDate(for: date("2026-11-03T00:00:00Z"), hasTime: false, allDayMinutes: 9 * 60 + 30, calendar: utc)
        #expect(alert == date("2026-11-03T09:30:00Z"))
    }

    @Test func snoozeOverridesAlert() {
        let reminder = Reminder(title: "Call", dueDate: date("2026-10-29T09:00:00Z"), hasTime: true)
        reminder.snooze(for: 3600, now: thursdayMorning)
        #expect(reminder.alertDate(allDayMinutes: 540, calendar: utc) == date("2026-10-29T11:00:00Z"))
    }

    @Test func settingAPastTimeDoesNotNag() {
        let reminder = Reminder(title: "Stretch")
        reminder.setDue(date("2026-10-29T08:00:00Z"), hasTime: true, now: thursdayMorning, calendar: utc)
        #expect(reminder.acknowledgedAt == thursdayMorning)
    }

    @Test func settingAFutureTimeArmsTheAlert() {
        let reminder = Reminder(title: "Stretch")
        reminder.acknowledgedAt = thursdayMorning
        reminder.setDue(date("2026-10-29T15:00:00Z"), hasTime: true, now: thursdayMorning, calendar: utc)
        #expect(reminder.acknowledgedAt == nil)
    }

    @Test func moveToTomorrowKeepsTimeOfDay() {
        let reminder = Reminder(title: "Gym", dueDate: date("2026-10-29T18:45:00Z"), hasTime: true)
        reminder.moveToDay(offset: 1, now: thursdayMorning, calendar: utc)
        #expect(reminder.dueDate == date("2026-10-30T18:45:00Z"))
        #expect(reminder.hasTime)
    }

    @Test func overdue() {
        let timed = Reminder(title: "A", dueDate: date("2026-10-29T09:00:00Z"), hasTime: true)
        let allDayToday = Reminder(title: "B", dueDate: date("2026-10-29T00:00:00Z"))
        let allDayYesterday = Reminder(title: "C", dueDate: date("2026-10-28T00:00:00Z"))
        #expect(timed.isOverdue(now: thursdayMorning, calendar: utc))
        #expect(!allDayToday.isOverdue(now: thursdayMorning, calendar: utc))
        #expect(allDayYesterday.isOverdue(now: thursdayMorning, calendar: utc))
    }
}
