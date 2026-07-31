import Foundation

private let focusCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    return calendar
}()

private func focusDate(_ hour: Int, _ minute: Int = 0) -> Date {
    focusCalendar.date(
        from: DateComponents(
            year: 2026,
            month: 7,
            day: 31,
            hour: hour,
            minute: minute
        )
    )!
}

@MainActor
private func makeFocusModel(
    onCompleted: @escaping () -> Void = {}
) -> FocusTimerModel {
    FocusTimerModel(
        store: FocusTimerStore(store: InMemoryKeyValueStore()),
        now: { focusDate(10, 0) },
        startsTimer: false,
        onCompleted: onCompleted
    )
}

let focusTimerTests: [TestCase] = [
    TestCase(name: "focus timer defaults to a 25 minute idle session") {
        let model = FocusTimerModel(
            store: FocusTimerStore(store: InMemoryKeyValueStore()),
            now: { focusDate(10, 0) },
            startsTimer: false,
            onCompleted: {}
        )

        try expectEqual(model.phase, .idle, "phase")
        try expectEqual(model.selectedMinutes, 25, "minutes")
        try expectEqual(model.remainingSeconds, 1_500, "remaining")
    },
    TestCase(name: "focus duration selection clamps to the supported range") {
        let model = makeFocusModel()

        model.select(minutes: 2)
        try expectEqual(model.selectedMinutes, 5, "minimum")
        model.select(minutes: 240)
        try expectEqual(model.selectedMinutes, 180, "maximum")
        model.adjustMinutes(by: -500)
        try expectEqual(model.selectedMinutes, 5, "adjusted minimum")
    },
    TestCase(name: "running focus timer follows its absolute deadline") {
        let model = makeFocusModel()

        model.start(at: focusDate(10, 0))
        model.refresh(at: focusDate(10, 5))

        try expectEqual(model.phase, .running, "phase")
        try expectEqual(model.remainingSeconds, 1_200, "remaining")
        try expect(abs(model.progress - 0.2) < 0.000_001, "progress")
    },
    TestCase(name: "focus timer pauses and resumes from exact remaining time") {
        let model = makeFocusModel()

        model.start(at: focusDate(10, 0))
        model.pause(at: focusDate(10, 5))
        try expectEqual(model.phase, .paused, "paused phase")
        try expectEqual(model.remainingSeconds, 1_200, "paused remaining")

        model.resume(at: focusDate(10, 10))
        model.refresh(at: focusDate(10, 15))
        try expectEqual(model.remainingSeconds, 900, "resumed remaining")
    },
    TestCase(name: "focus timer completes once and resets cleanly") {
        var completions = 0
        let model = makeFocusModel(onCompleted: { completions += 1 })

        model.start(at: focusDate(10, 0))
        model.refresh(at: focusDate(10, 25))
        model.refresh(at: focusDate(10, 26))

        try expectEqual(model.phase, .completed, "completed phase")
        try expectEqual(completions, 1, "completion callbacks")

        model.reset()
        try expectEqual(model.phase, .idle, "reset phase")
        try expectEqual(model.remainingSeconds, 1_500, "reset remaining")
    },
    TestCase(name: "running focus timer restores from persisted deadline") {
        let memory = InMemoryKeyValueStore()
        let store = FocusTimerStore(store: memory)
        let first = FocusTimerModel(
            store: store,
            now: { focusDate(10, 0) },
            startsTimer: false,
            onCompleted: {}
        )
        first.start(at: focusDate(10, 0))

        let restored = FocusTimerModel(
            store: store,
            now: { focusDate(10, 10) },
            startsTimer: false,
            onCompleted: {}
        )

        try expectEqual(restored.phase, .running, "restored phase")
        try expectEqual(restored.remainingSeconds, 900, "restored remaining")
    }
]
