import Foundation

/// Decides which local notifications should be pending right now.
///
/// iOS can't tell the app that a notification was ignored, so re-reminders are
/// scheduled up front: the alert itself, then one every `nagInterval` after it.
/// Interacting with a notification acknowledges the reminder, after which the
/// pending follow-ups are dropped on the next sync. iOS keeps at most 64 pending
/// notifications per app, so the plan keeps only the soonest `limit`, and is
/// rebuilt whenever the app runs or reminders change.
enum NotificationPlanner {
    struct Item: Equatable {
        var reminderID: UUID
        var alertDate: Date
        var acknowledgedAt: Date?

        /// Whether this reminder's current alert still wants the user's attention.
        var isActive: Bool {
            guard let acknowledgedAt else { return true }
            return acknowledgedAt < alertDate
        }
    }

    struct Planned: Equatable {
        var reminderID: UUID
        var fireDate: Date
        /// 0 for the original alert, 1+ for re-reminders.
        var followUp: Int

        var identifier: String { "\(reminderID.uuidString)#\(followUp)" }
    }

    static let defaultLimit = 60

    static func plan(_ items: [Item], now: Date, nagInterval: TimeInterval?, limit: Int = defaultLimit) -> [Planned] {
        guard limit > 0 else { return [] }
        let interval = nagInterval.flatMap { $0 > 0 ? $0 : nil }
        var planned: [Planned] = []

        for item in items where item.isActive {
            var index = 0
            if item.alertDate <= now {
                // Already went off and was ignored: pick up at the next re-reminder.
                guard let interval else { continue }
                index = Int(now.timeIntervalSince(item.alertDate) / interval) + 1
            }
            guard let interval else {
                planned.append(Planned(reminderID: item.reminderID, fireDate: item.alertDate, followUp: 0))
                continue
            }
            for i in index..<(index + limit) {
                let fireDate = item.alertDate.addingTimeInterval(Double(i) * interval)
                planned.append(Planned(reminderID: item.reminderID, fireDate: fireDate, followUp: i))
            }
        }

        planned.sort { ($0.fireDate, $0.reminderID.uuidString) < ($1.fireDate, $1.reminderID.uuidString) }
        return Array(planned.prefix(limit))
    }
}
