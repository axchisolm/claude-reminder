import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage(AppSettings.nagEnabledKey) private var nagEnabled = true
    @AppStorage(AppSettings.nagIntervalKey) private var nagInterval = AppSettings.defaultNagInterval
    @AppStorage(AppSettings.allDayAlertMinutesKey) private var allDayMinutes = AppSettings.defaultAllDayAlertMinutes
    @State private var notificationsDenied = false

    private let choices = AppSettings.nagIntervalChoices

    var body: some View {
        NavigationStack {
            Form {
                if notificationsDenied {
                    Section {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        } label: {
                            Label("Turn On Notifications", systemImage: "bell.slash.fill")
                        }
                    } footer: {
                        Text("Notifications are off for Nudge, so it can't remind you of anything.")
                    }
                }

                Section {
                    Toggle(isOn: $nagEnabled.animation(.snappy)) {
                        Label { Text("Keep Nudging Me") } icon: {
                            IconBadge(systemName: "bell.badge.fill", color: .accentColor)
                        }
                    }
                    if nagEnabled {
                        Stepper(value: intervalIndex, in: 0...(choices.count - 1)) {
                            HStack {
                                Label { Text("Every") } icon: {
                                    IconBadge(systemName: "arrow.clockwise", color: .orange)
                                }
                                Spacer()
                                Text(AppSettings.intervalText(minutes: nagInterval))
                                    .monospacedDigit()
                                    .foregroundStyle(.tint)
                                    .contentTransition(.numericText(value: Double(nagInterval)))
                            }
                        }
                    }
                } header: {
                    Text("Re-reminders")
                } footer: {
                    Text(nagEnabled
                        ? "If you ignore a reminder, Nudge reminds you again every \(AppSettings.intervalText(minutes: nagInterval)) until you mark it done, snooze it, or open it."
                        : "You'll get one notification per reminder.")
                }

                Section {
                    DatePicker(selection: allDayTime, displayedComponents: .hourAndMinute) {
                        Label { Text("Remind At") } icon: {
                            IconBadge(systemName: "sun.horizon.fill", color: .yellow)
                        }
                    }
                } header: {
                    Text("Reminders Without a Time")
                } footer: {
                    Text("Reminders with a date but no time notify you at this time of day.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.bold()
                }
            }
            .task {
                let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
                notificationsDenied = status == .denied
            }
        }
    }

    private var intervalIndex: Binding<Int> {
        Binding {
            choices.firstIndex { $0 >= nagInterval } ?? choices.count - 1
        } set: { index in
            withAnimation(.snappy) { nagInterval = choices[index] }
        }
    }

    private var allDayTime: Binding<Date> {
        Binding {
            Calendar.current.date(byAdding: .minute, value: allDayMinutes, to: Calendar.current.startOfDay(for: .now)) ?? .now
        } set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            allDayMinutes = (parts.hour ?? 9) * 60 + (parts.minute ?? 0)
        }
    }
}

#Preview {
    SettingsView()
}
