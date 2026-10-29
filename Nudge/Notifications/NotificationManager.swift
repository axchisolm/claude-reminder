import Foundation
import SwiftData
import UserNotifications

/// Identifiers shared between scheduling and the notification delegate.
enum NotificationID {
    static let category = "REMINDER"
    static let completeAction = "COMPLETE"
    static let snoozeAction = "SNOOZE"
    static let reminderKey = "reminderID"
}

/// Keeps the system's pending notifications in step with the reminders.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private static let nudgeLines = [
        "Just a friendly nudge 👋",
        "Still on your list.",
        "This one's still waiting for you.",
        "Psst — don't forget!",
        "Nudge, nudge.",
    ]

    private let center = UNUserNotificationCenter.current()
    private var pendingSync: Task<Void, Never>?
    private var runningSync: Task<Void, Never>?

    private init() {}

    func registerCategories() {
        let complete = UNNotificationAction(
            identifier: NotificationID.completeAction,
            title: "Mark as Done",
            options: [],
            icon: UNNotificationActionIcon(systemImageName: "checkmark.circle")
        )
        let snooze = UNNotificationAction(
            identifier: NotificationID.snoozeAction,
            title: "Snooze 1 Hour",
            options: [],
            icon: UNNotificationActionIcon(systemImageName: "zzz")
        )
        let category = UNNotificationCategory(
            identifier: NotificationID.category,
            actions: [complete, snooze],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    /// Coalesces a burst of edits into one sync.
    func scheduleSync() {
        pendingSync?.cancel()
        pendingSync = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await sync()
        }
    }

    /// Rebuilds every pending notification from the current reminders.
    /// Syncs run one at a time so an older plan never lands after a newer one.
    func sync() async {
        let previous = runningSync
        let task = Task {
            await previous?.value
            await performSync()
        }
        runningSync = task
        await task.value
    }

    private func performSync() async {
        let context = Persistence.container.mainContext
        let descriptor = FetchDescriptor<Reminder>(predicate: #Predicate { $0.isCompleted == false })
        let reminders = (try? context.fetch(descriptor)) ?? []
        let allDayMinutes = AppSettings.allDayAlertMinutes

        var byID: [UUID: Reminder] = [:]
        var items: [NotificationPlanner.Item] = []
        for reminder in reminders {
            guard let alert = reminder.alertDate(allDayMinutes: allDayMinutes) else { continue }
            byID[reminder.id] = reminder
            items.append(.init(reminderID: reminder.id, alertDate: alert, acknowledgedAt: reminder.acknowledgedAt))
        }

        let plan = NotificationPlanner.plan(items, now: .now, nagInterval: AppSettings.nagInterval)

        center.removeAllPendingNotificationRequests()
        await clearDelivered(keeping: Set(items.filter(\.isActive).map(\.reminderID)))

        guard !plan.isEmpty, await isAuthorized() else { return }
        for entry in plan {
            guard let reminder = byID[entry.reminderID] else { continue }
            try? await center.add(request(for: entry, reminder: reminder))
        }
    }

    /// Applies a notification action (or a plain tap) to its reminder.
    func handle(actionIdentifier: String, reminderID: UUID) async {
        let context = Persistence.container.mainContext
        var descriptor = FetchDescriptor<Reminder>(predicate: #Predicate { $0.id == reminderID })
        descriptor.fetchLimit = 1
        guard let reminder = try? context.fetch(descriptor).first else { return }

        switch actionIdentifier {
        case NotificationID.completeAction:
            reminder.complete()
        case NotificationID.snoozeAction:
            reminder.snooze(for: AppSettings.snoozeInterval)
        default:
            // Opening the notification counts as having seen it.
            reminder.acknowledgedAt = .now
        }
        try? context.save()
        await sync()
    }

    private func request(for entry: NotificationPlanner.Planned, reminder: Reminder) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        if entry.followUp == 0 {
            content.body = reminder.notes
        } else {
            let line = Self.nudgeLines[(entry.followUp - 1) % Self.nudgeLines.count]
            content.body = reminder.notes.isEmpty ? line : "\(line) \(reminder.notes)"
        }
        content.sound = .default
        content.categoryIdentifier = NotificationID.category
        content.threadIdentifier = reminder.id.uuidString
        content.userInfo = [NotificationID.reminderKey: reminder.id.uuidString]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: entry.fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: entry.identifier, content: content, trigger: trigger)
    }

    /// Removes delivered notifications for reminders that no longer need attention.
    private func clearDelivered(keeping activeIDs: Set<UUID>) async {
        let delivered = await center.deliveredNotifications()
        let stale = delivered.compactMap { notification -> String? in
            let raw = notification.request.content.userInfo[NotificationID.reminderKey] as? String
            guard let id = raw.flatMap(UUID.init(uuidString:)), activeIDs.contains(id) else {
                return notification.request.identifier
            }
            return nil
        }
        center.removeDeliveredNotifications(withIdentifiers: stale)
    }

    private func isAuthorized() async -> Bool {
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .denied:
            return false
        default:
            return true
        }
    }
}
