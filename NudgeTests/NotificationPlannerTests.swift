import Foundation
import Testing
@testable import Nudge

struct NotificationPlannerTests {
    private let fifteenMinutes: TimeInterval = 15 * 60
    private let a = UUID()
    private let b = UUID()

    @Test func futureAlertFiresThenRepeats() {
        let alert = date("2026-10-29T12:00:00Z")
        let plan = NotificationPlanner.plan(
            [.init(reminderID: a, alertDate: alert)],
            now: thursdayMorning, nagInterval: fifteenMinutes, limit: 3
        )
        #expect(plan.map(\.fireDate) == [
            alert,
            date("2026-10-29T12:15:00Z"),
            date("2026-10-29T12:30:00Z"),
        ])
        #expect(plan.map(\.followUp) == [0, 1, 2])
    }

    @Test func ignoredAlertResumesAtNextInterval() {
        // Went off at 9:00; it's 10:00, so the next nudge is 10:15.
        let plan = NotificationPlanner.plan(
            [.init(reminderID: a, alertDate: date("2026-10-29T09:00:00Z"))],
            now: thursdayMorning, nagInterval: fifteenMinutes, limit: 2
        )
        #expect(plan.map(\.fireDate) == [date("2026-10-29T10:15:00Z"), date("2026-10-29T10:30:00Z")])
        #expect(plan.first?.followUp == 5)
    }

    @Test func acknowledgedAlertStopsNagging() {
        let plan = NotificationPlanner.plan(
            [.init(reminderID: a, alertDate: date("2026-10-29T09:00:00Z"), acknowledgedAt: date("2026-10-29T09:05:00Z"))],
            now: thursdayMorning, nagInterval: fifteenMinutes
        )
        #expect(plan.isEmpty)
    }

    @Test func staleAcknowledgementDoesNotSilenceANewAlert() {
        let plan = NotificationPlanner.plan(
            [.init(reminderID: a, alertDate: date("2026-10-29T12:00:00Z"), acknowledgedAt: date("2026-10-28T09:00:00Z"))],
            now: thursdayMorning, nagInterval: fifteenMinutes, limit: 1
        )
        #expect(plan.count == 1)
    }

    @Test func nagDisabledSchedulesOnlyTheAlert() {
        let plan = NotificationPlanner.plan(
            [
                .init(reminderID: a, alertDate: date("2026-10-29T12:00:00Z")),
                .init(reminderID: b, alertDate: date("2026-10-29T09:00:00Z")),
            ],
            now: thursdayMorning, nagInterval: nil
        )
        #expect(plan == [.init(reminderID: a, fireDate: date("2026-10-29T12:00:00Z"), followUp: 0)])
    }

    @Test func limitKeepsTheSoonestAcrossReminders() {
        let plan = NotificationPlanner.plan(
            [
                .init(reminderID: a, alertDate: date("2026-10-29T11:00:00Z")),
                .init(reminderID: b, alertDate: date("2026-10-29T11:05:00Z")),
            ],
            now: thursdayMorning, nagInterval: fifteenMinutes, limit: 4
        )
        #expect(plan.count == 4)
        #expect(plan.map(\.reminderID) == [a, b, a, b])
        #expect(plan.last?.fireDate == date("2026-10-29T11:20:00Z"))
    }

    @Test func identifiersAreUnique() {
        let plan = NotificationPlanner.plan(
            [.init(reminderID: a, alertDate: date("2026-10-29T11:00:00Z"))],
            now: thursdayMorning, nagInterval: 60
        )
        #expect(Set(plan.map(\.identifier)).count == plan.count)
        #expect(plan.count == NotificationPlanner.defaultLimit)
    }
}
