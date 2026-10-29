import SwiftUI

struct ReminderRow: View {
    let reminder: Reminder
    let now: Date
    let tint: Color
    let onEdit: () -> Void

    /// Checked state shown in the row. Runs slightly ahead of `reminder.isCompleted`
    /// so a completed row lingers long enough to enjoy (and to undo) before it leaves.
    @State private var checked: Bool
    @State private var commit: Task<Void, Never>?

    init(reminder: Reminder, now: Date, tint: Color, onEdit: @escaping () -> Void) {
        self.reminder = reminder
        self.now = now
        self.tint = tint
        self.onEdit = onEdit
        _checked = State(initialValue: reminder.isCompleted)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CheckCircle(isOn: checked, tint: tint, action: toggle)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.title)
                    .strikethrough(checked, color: .secondary)
                    .foregroundStyle(checked ? Color.secondary : Color.primary)

                if !reminder.notes.isEmpty {
                    Text(reminder.notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if reminder.dueDate != nil || reminder.isSnoozed(now: now) {
                    details
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onEdit)
        }
        .padding(.vertical, 2)
        .onChange(of: reminder.isCompleted) { _, completed in
            checked = completed
        }
        .sensoryFeedback(trigger: checked) { _, isChecked in
            isChecked ? SensoryFeedback.success : .selection
        }
    }

    private var details: some View {
        HStack(spacing: 10) {
            if let due = reminder.dueDate {
                Label(
                    DueFormatter.label(due: due, hasTime: reminder.hasTime, now: now),
                    systemImage: reminder.hasTime ? "clock" : "calendar"
                )
                .foregroundStyle(reminder.isOverdue(now: now) ? Color.red : Color.secondary)
            }
            if reminder.isSnoozed(now: now) {
                Label("Snoozed", systemImage: "zzz")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
        .labelStyle(TightLabelStyle())
    }

    private func toggle() {
        commit?.cancel()

        if reminder.isCompleted {
            withAnimation(.snappy) {
                checked = false
                reminder.uncomplete()
            }
            return
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
            checked.toggle()
        }
        guard checked else { return }

        commit = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            withAnimation(.snappy) {
                reminder.complete()
            }
        }
    }
}

private struct TightLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.icon
            configuration.title
        }
    }
}
