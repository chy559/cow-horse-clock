import Foundation

private let earningsCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    calendar.locale = Locale(identifier: "en_US_POSIX")
    return calendar
}()

private func earningsDate(_ value: String) -> Date {
    let formatter = DateFormatter()
    formatter.calendar = earningsCalendar
    formatter.timeZone = earningsCalendar.timeZone
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter.date(from: value)!
}

private func snapshot(_ value: String, isWorkday: Bool = true) -> EarningsSnapshot {
    EarningsEngine.snapshot(
        at: earningsDate(value),
        settings: .default,
        isWorkday: isWorkday,
        calendar: earningsCalendar
    )
}

let earningsEngineTests: [TestCase] = [
    TestCase(name: "before work earns zero") {
        let result = snapshot("2026-07-30 08:30:00")

        try expectEqual(result.state, .beforeWork, "state")
        try expectEqual(result.earnedCents, Decimal.zero, "earnings")
        try expectEqual(result.secondsUntilNextTransition, 30 * 60, "countdown")
    },
    TestCase(name: "morning halfway earns proportional amount") {
        let result = snapshot("2026-07-30 10:30:00")

        try expectEqual(result.state, .workingMorning, "state")
        try expectEqual(result.earnedCents, Decimal(8_000), "earnings")
        try expect(abs(result.progress - 0.2) < 0.000_001, "progress should be 20%")
    },
    TestCase(name: "lunch pauses at morning amount") {
        let result = snapshot("2026-07-30 12:45:00")

        try expectEqual(result.state, .lunch, "state")
        try expectEqual(result.earnedCents, Decimal(16_000), "earnings")
        try expectEqual(result.secondsUntilNextTransition, 45 * 60, "countdown")
    },
    TestCase(name: "afternoon resumes proportional earnings") {
        let result = snapshot("2026-07-30 15:45:00")

        try expectEqual(result.state, .workingAfternoon, "state")
        try expectEqual(result.earnedCents, Decimal(28_000), "earnings")
        try expect(abs(result.progress - 0.7) < 0.000_001, "progress should be 70%")
    },
    TestCase(name: "finish caps earnings at daily salary") {
        let result = snapshot("2026-07-30 18:00:00")

        try expectEqual(result.state, .finished, "state")
        try expectEqual(result.earnedCents, Decimal(40_000), "earnings")
        try expectEqual(result.progress, 1, "progress")
        try expectEqual(result.secondsUntilNextTransition, nil, "countdown")
    },
    TestCase(name: "rest day earns zero") {
        let result = snapshot("2026-07-30 15:00:00", isWorkday: false)

        try expectEqual(result.state, .restDay, "state")
        try expectEqual(result.earnedCents, Decimal.zero, "earnings")
        try expectEqual(result.rateCentsPerSecond, Decimal.zero, "rate")
    },
    TestCase(name: "zero salary remains valid and finite") {
        var settings = WorkSettings.default
        settings.dailySalaryCents = 0

        let result = EarningsEngine.snapshot(
            at: earningsDate("2026-07-30 10:00:00"),
            settings: settings,
            isWorkday: true,
            calendar: earningsCalendar
        )

        try expectEqual(result.earnedCents, Decimal.zero, "earnings")
        try expectEqual(result.rateCentsPerSecond, Decimal.zero, "rate")
    }
]
