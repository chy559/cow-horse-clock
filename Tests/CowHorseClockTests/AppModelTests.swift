import Foundation

private final class FakeLaunchAtLoginService: LaunchAtLoginControlling {
    var calls: [Bool] = []

    func setEnabled(_ enabled: Bool) throws {
        calls.append(enabled)
    }
}

private let appModelCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    return calendar
}()

private func appModelDate(_ hour: Int, _ minute: Int = 0) -> Date {
    appModelCalendar.date(
        from: DateComponents(
            year: 2026,
            month: 7,
            day: 30,
            hour: hour,
            minute: minute
        )
    )!
}

@MainActor
private func makeAppModel(
    settings: WorkSettings = .default
) throws -> (AppModel, SettingsStore, FakeLaunchAtLoginService) {
    let memory = InMemoryKeyValueStore()
    let settingsStore = SettingsStore(store: memory)
    try settingsStore.save(settings)
    let launchService = FakeLaunchAtLoginService()
    let model = AppModel(
        settingsStore: settingsStore,
        ledgerStore: LedgerStore(store: memory, calendar: appModelCalendar),
        launchAtLoginService: launchService,
        calendar: appModelCalendar,
        now: { appModelDate(10, 30) },
        startsTimer: false
    )
    return (model, settingsStore, launchService)
}

let appModelTests: [TestCase] = [
    TestCase(name: "app model derives its initial snapshot from the wall clock") {
        let (model, _, _) = try makeAppModel()

        try expectEqual(model.snapshot.state, .workingMorning, "state")
        try expectEqual(model.snapshot.earnedCents, Decimal(8_000), "earnings")
    },
    TestCase(name: "invalid settings cannot be saved") {
        let (model, _, _) = try makeAppModel()
        var invalid = WorkSettings.default
        invalid.defaultWeekdays = []

        do {
            try model.saveSettings(invalid, at: appModelDate(10, 30))
            throw TestFailure(description: "save should fail")
        } catch AppModelError.invalidSettings(let errors) {
            try expectEqual(errors, [.noWorkday], "errors")
        }
    },
    TestCase(name: "first setup stores tracking start date") {
        let (model, store, _) = try makeAppModel()
        var draft = WorkSettings.default
        draft.dailySalaryCents = 50_000

        try model.completeSetup(draft, at: appModelDate(10, 30))

        let saved = store.load()
        try expect(saved.trackingStartDate != nil, "tracking should start")
        try expectEqual(saved.dailySalaryCents, 50_000, "salary")
        try expectEqual(model.route, .dashboard, "route")
    },
    TestCase(name: "launch at login changes are forwarded to the service") {
        let (model, _, launchService) = try makeAppModel()
        var settings = WorkSettings.default
        settings.launchAtLogin = true

        try model.saveSettings(settings, at: appModelDate(10, 30))

        try expectEqual(launchService.calls, [true], "launch calls")
    }
]
