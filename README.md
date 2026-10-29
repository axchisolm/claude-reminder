# Nudge

A clean, native iOS reminders app that doesn't let things slip. Built with SwiftUI and SwiftData.

## Features

- **Three sections.** Reminders sort themselves into **Today**, **This Week**, and **Later** based on their date.
  - Today: reminders with no date, due today, or overdue (overdue dates show in red).
  - This Week: tomorrow through the next seven days.
  - Later: everything after that.
  - This Week and Later collapse with a tap on their header, so you can focus on Today. The app remembers which sections you collapsed.
- **Reminders that keep reminding.** You get a notification at the reminder's date and time. If you ignore it, Nudge reminds you again every *N* minutes (default 15, change it in Settings) until you mark it done, snooze it, or tap the notification.
  - Notification actions: **Mark as Done** and **Snooze 1 Hour**.
  - Reminders with a date but no time notify at a time you choose (default 9:00 AM).
  - Reminders without a date don't send notifications.
- **Interactions.** The checkbox fills with a spring and a ripple, plays a haptic, and the reminder stays on screen for a moment (tap again to undo) before it leaves. Swipe right on a Today reminder to push it to tomorrow, or on a later one to pull it into Today. Swipe left to delete. Quick-date chips (Today, Tomorrow, Weekend, Next Week) in the editor.
- **Show Completed** toggle in the ••• menu.

## Running

Requires **Xcode 16+** and iOS 17+.

1. Open `Nudge.xcodeproj`.
2. Select the **Nudge** target → *Signing & Capabilities*, choose your team, and change the bundle ID (`com.example.Nudge`) if needed.
3. Run on a simulator or device. Run the unit tests with ⌘U.

## How re-reminders work

iOS doesn't tell an app when you ignore a notification, so Nudge schedules the follow-ups ahead of time: the alert, then one every *N* minutes after it. Interacting with a notification (tapping it, Done, Snooze) cancels the rest. iOS lets an app keep only 64 pending notifications, so Nudge keeps the soonest 60 across all reminders and rebuilds the schedule every time the app opens or a reminder changes. The scheduling logic is in `NotificationPlanner` and has unit tests.

## Layout

```
Nudge/
  NudgeApp.swift              App entry + notification delegate
  AppSettings.swift           User preferences (re-remind interval, all-day alert time)
  Persistence.swift           SwiftData container (+ preview data)
  Model/                      Reminder model, bucketing, date shortcuts, labels
  Notifications/              Pure planner + UNUserNotificationCenter sync
  Views/                      List, row, checkbox, editor, settings
NudgeTests/                   Swift Testing unit tests for the pure logic
```
