import SwiftData
import SwiftUI

/// Creates a new reminder (`reminder == nil`) or edits an existing one.
struct ReminderEditor: View {
    let reminder: Reminder?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(AppSettings.nagEnabledKey) private var nagEnabled = true
    @AppStorage(AppSettings.nagIntervalKey) private var nagInterval = AppSettings.defaultNagInterval
    @AppStorage(AppSettings.allDayAlertMinutesKey) private var allDayMinutes = AppSettings.defaultAllDayAlertMinutes

    @State private var title: String
    @State private var notes: String
    @State private var hasDate: Bool
    @State private var hasTime: Bool
    @State private var date: Date
    @FocusState private var titleFocused: Bool

    private let calendar = Calendar.current

    init(reminder: Reminder?) {
        self.reminder = reminder
        _title = State(initialValue: reminder?.title ?? "")
        _notes = State(initialValue: reminder?.notes ?? "")
        _hasDate = State(initialValue: reminder?.dueDate != nil)
        _hasTime = State(initialValue: reminder?.hasTime ?? false)
        _date = State(initialValue: reminder?.dueDate ?? Calendar.current.nextHour(after: .now))
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var selectedQuickDate: QuickDate? {
        hasDate ? QuickDate.matching(date, now: .now, calendar: calendar) : nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What needs doing?", text: $title)
                        .font(.title3.weight(.medium))
                        .focused($titleFocused)
                        .submitLabel(.done)
                        .onSubmit { if !trimmedTitle.isEmpty { save() } }
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(1...6)
                        .foregroundStyle(.secondary)
                }

                Section {
                    QuickDateChips(selected: selectedQuickDate, onSelect: pick)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section {
                    Toggle(isOn: dateEnabled) {
                        Label { Text("Date") } icon: { IconBadge(systemName: "calendar", color: .red) }
                    }
                    if hasDate {
                        DatePicker("Day", selection: $date, displayedComponents: .date)
                    }
                    Toggle(isOn: timeEnabled) {
                        Label { Text("Time") } icon: { IconBadge(systemName: "clock.fill", color: .blue) }
                    }
                    if hasTime {
                        DatePicker("At", selection: $date, displayedComponents: .hourAndMinute)
                    }
                } footer: {
                    Text(scheduleFooter)
                        .contentTransition(.opacity)
                }

                if let reminder {
                    Section {
                        Button(role: .destructive) {
                            withAnimation { context.delete(reminder) }
                            dismiss()
                        } label: {
                            Label("Delete Reminder", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(reminder == nil ? "New Reminder" : "Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(reminder == nil ? "Add" : "Done", action: save)
                        .bold()
                        .disabled(trimmedTitle.isEmpty)
                }
            }
            .task {
                guard reminder == nil else { return }
                // Give the sheet a beat to settle so the keyboard rides up with it.
                try? await Task.sleep(for: .milliseconds(350))
                titleFocused = true
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var scheduleFooter: String {
        guard hasDate else { return "Without a date, this lives in Today." }
        let alertTime: String
        if hasTime {
            alertTime = date.formatted(date: .omitted, time: .shortened)
        } else {
            let alert = Reminder.alertDate(for: date, hasTime: false, allDayMinutes: allDayMinutes, calendar: calendar)
            alertTime = alert.formatted(date: .omitted, time: .shortened)
        }
        let nag = nagEnabled ? ", then every \(AppSettings.intervalText(minutes: nagInterval)) until it's done" : ""
        return "You'll be reminded at \(alertTime)\(nag)."
    }

    private var dateEnabled: Binding<Bool> {
        Binding {
            hasDate
        } set: { on in
            withAnimation(.snappy) {
                hasDate = on
                if !on { hasTime = false }
            }
        }
    }

    private var timeEnabled: Binding<Bool> {
        Binding {
            hasTime
        } set: { on in
            withAnimation(.snappy) {
                if on {
                    if !hasDate { date = .now }
                    date = calendar.combine(day: date, time: calendar.nextHour(after: .now))
                    hasDate = true
                }
                hasTime = on
            }
        }
    }

    private func pick(_ option: QuickDate) {
        withAnimation(.snappy) {
            if option == selectedQuickDate {
                hasDate = false
                hasTime = false
                return
            }
            let day = option.day(from: .now, calendar: calendar)
            date = calendar.combine(day: day, time: date)
            hasDate = true
        }
    }

    private func save() {
        guard !trimmedTitle.isEmpty else { return }
        let due: Date? = hasDate ? (hasTime ? calendar.combine(day: date, time: date) : calendar.startOfDay(for: date)) : nil

        if let reminder {
            reminder.title = trimmedTitle
            reminder.notes = notes
            if reminder.dueDate != due || reminder.hasTime != hasTime {
                reminder.setDue(due, hasTime: hasTime)
            }
        } else {
            let new = Reminder(title: trimmedTitle, notes: notes)
            new.setDue(due, hasTime: hasTime)
            withAnimation(.snappy) { context.insert(new) }
        }
        dismiss()
    }
}

#Preview {
    ReminderEditor(reminder: nil)
        .modelContainer(Persistence.preview)
}
