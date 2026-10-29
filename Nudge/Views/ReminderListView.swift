import SwiftData
import SwiftUI

struct ReminderListView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Reminder.createdAt) private var reminders: [Reminder]

    @AppStorage("showCompleted") private var showCompleted = false
    @AppStorage("expanded.thisWeek") private var thisWeekExpanded = true
    @AppStorage("expanded.later") private var laterExpanded = false
    @AppStorage(AppSettings.nagEnabledKey) private var nagEnabled = true
    @AppStorage(AppSettings.nagIntervalKey) private var nagInterval = AppSettings.defaultNagInterval
    @AppStorage(AppSettings.allDayAlertMinutesKey) private var allDayMinutes = AppSettings.defaultAllDayAlertMinutes

    @State private var editor: EditorItem?
    @State private var showingSettings = false
    /// Drives bucketing and overdue styling; refreshed periodically and on foreground.
    @State private var now = Date.now

    var body: some View {
        NavigationStack {
            List {
                ForEach(ReminderBucket.allCases) { bucket in
                    section(bucket)
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .navigationTitle(now.formatted(.dateTime.weekday(.wide)))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { menu }
            }
            .safeAreaInset(edge: .bottom) { newReminderBar }
            .sheet(item: $editor) { item in
                ReminderEditor(reminder: item.reminder)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                now = .now
            }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            guard phase == .active else { return }
            now = .now
            NotificationManager.shared.scheduleSync()
        }
        .onChange(of: notificationFingerprint) {
            NotificationManager.shared.scheduleSync()
        }
    }

    // MARK: Sections

    @ViewBuilder
    private func section(_ bucket: ReminderBucket) -> some View {
        let items = items(in: bucket)
        let expanded = isExpanded(bucket)

        Section {
            if expanded {
                if items.isEmpty {
                    EmptySectionRow(bucket: bucket, now: now)
                } else {
                    ForEach(items) { reminder in
                        row(for: reminder, in: bucket)
                    }
                }
            }
        } header: {
            SectionHeader(
                bucket: bucket,
                count: items.filter { !$0.isCompleted }.count,
                isExpanded: expanded,
                toggle: bucket == .today ? nil : { toggleExpanded(bucket) }
            )
        }
    }

    private func row(for reminder: Reminder, in bucket: ReminderBucket) -> some View {
        ReminderRow(reminder: reminder, now: now, tint: bucket.tint) {
            editor = EditorItem(reminder: reminder)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                withAnimation(.snappy) { context.delete(reminder) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            if !reminder.isCompleted {
                if bucket == .today {
                    Button {
                        withAnimation(.snappy) { reminder.moveToDay(offset: 1, now: now) }
                    } label: {
                        Label("Tomorrow", systemImage: "arrow.uturn.forward")
                    }
                    .tint(.indigo)
                } else {
                    Button {
                        withAnimation(.snappy) { reminder.moveToDay(offset: 0, now: now) }
                    } label: {
                        Label("Today", systemImage: "sun.max.fill")
                    }
                    .tint(.accentColor)
                }
            }
        }
    }

    private func items(in bucket: ReminderBucket) -> [Reminder] {
        reminders
            .filter { $0.bucket(now: now) == bucket && (showCompleted || !$0.isCompleted) }
            .sorted(by: Self.displayOrder)
    }

    /// Open items first, then by due date (undated last), then oldest first.
    private static func displayOrder(_ a: Reminder, _ b: Reminder) -> Bool {
        if a.isCompleted != b.isCompleted { return !a.isCompleted }
        switch (a.dueDate, b.dueDate) {
        case let (x?, y?) where x != y: return x < y
        case (.some, nil): return true
        case (nil, .some): return false
        default: return a.createdAt < b.createdAt
        }
    }

    private func isExpanded(_ bucket: ReminderBucket) -> Bool {
        switch bucket {
        case .today: true
        case .thisWeek: thisWeekExpanded
        case .later: laterExpanded
        }
    }

    private func toggleExpanded(_ bucket: ReminderBucket) {
        withAnimation(.snappy) {
            switch bucket {
            case .today: break
            case .thisWeek: thisWeekExpanded.toggle()
            case .later: laterExpanded.toggle()
            }
        }
    }

    // MARK: Chrome

    private var menu: some View {
        Menu {
            Toggle(isOn: $showCompleted.animation(.snappy)) {
                Label("Show Completed", systemImage: "checkmark.circle")
            }
            Button {
                showingSettings = true
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    private var newReminderBar: some View {
        HStack {
            Button {
                editor = EditorItem(reminder: nil)
            } label: {
                Label("New Reminder", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .imageScale(.large)
            }
            .buttonStyle(BouncyButtonStyle())
            .foregroundStyle(.tint)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }

    /// Everything that affects scheduled notifications; a change triggers a resync.
    private var notificationFingerprint: [String] {
        reminders.map { r in
            [
                r.id.uuidString, r.title, r.notes,
                "\(r.dueDate?.timeIntervalSince1970 ?? 0)", "\(r.hasTime)", "\(r.isCompleted)",
                "\(r.acknowledgedAt?.timeIntervalSince1970 ?? 0)", "\(r.snoozedUntil?.timeIntervalSince1970 ?? 0)",
            ].joined(separator: "|")
        } + ["\(nagEnabled)|\(nagInterval)|\(allDayMinutes)"]
    }
}

private struct EditorItem: Identifiable {
    let id = UUID()
    let reminder: Reminder?
}

private struct EmptySectionRow: View {
    let bucket: ReminderBucket
    let now: Date

    private static let cheers: [(title: String, subtitle: String)] = [
        ("All clear!", "Nothing left for today. Enjoy it."),
        ("You're all caught up", "Go do something fun."),
        ("Nothing to do!", "Treat yourself — you've earned it."),
        ("Clean slate", "Today is wide open."),
    ]

    var body: some View {
        if bucket == .today {
            let day = Calendar.current.ordinality(of: .day, in: .era, for: now) ?? 0
            let cheer = Self.cheers[day % Self.cheers.count]
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor.gradient)
                    .symbolEffect(.pulse, options: .repeating.speed(0.4))
                VStack(alignment: .leading, spacing: 2) {
                    Text(cheer.title).font(.headline)
                    Text(cheer.subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
        } else {
            Text("Nothing scheduled")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    ReminderListView()
        .modelContainer(Persistence.preview)
}
