import Foundation
import SwiftData

enum Persistence {
    /// The app's store, shared by the UI and the notification handlers.
    @MainActor
    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: Reminder.self)
        } catch {
            fatalError("Could not open the reminders store: \(error)")
        }
    }()

    /// An in-memory store filled with sample reminders, for previews.
    @MainActor
    static let preview: ModelContainer = {
        let container = try! ModelContainer(
            for: Reminder.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        func day(_ offset: Int, hour: Int? = nil) -> Date {
            let date = calendar.date(byAdding: .day, value: offset, to: today)!
            guard let hour else { return date }
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
        }

        let samples = [
            Reminder(title: "Water the plants"),
            Reminder(title: "Call Mom", notes: "Ask about Thanksgiving", dueDate: day(0, hour: 18), hasTime: true),
            Reminder(title: "Return library books", dueDate: day(-1)),
            Reminder(title: "Dentist", dueDate: day(2, hour: 10), hasTime: true),
            Reminder(title: "Pick up dry cleaning", dueDate: day(4)),
            Reminder(title: "Renew passport", notes: "Photos first!", dueDate: day(21)),
        ]
        for sample in samples {
            container.mainContext.insert(sample)
        }
        return container
    }()
}
