import Foundation

/// A fixed Gregorian/UTC calendar so tests don't depend on the device's settings.
let utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    calendar.firstWeekday = 1
    return calendar
}()

func date(_ iso: String) -> Date {
    try! Date(iso, strategy: .iso8601)
}

/// Thursday, October 29, 2026, 10:00 UTC.
let thursdayMorning = date("2026-10-29T10:00:00Z")
