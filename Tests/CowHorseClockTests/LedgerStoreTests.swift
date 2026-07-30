import Foundation

private final class InMemoryKeyValueStore: KeyValueStore {
    var values: [String: Data] = [:]

    func data(forKey defaultName: String) -> Data? {
        values[defaultName]
    }

    func set(_ value: Any?, forKey defaultName: String) {
        values[defaultName] = value as? Data
    }
}

private let ledgerCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    return calendar
}()

private func ledgerDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
    ledgerCalendar.date(
        from: DateComponents(year: year, month: month, day: day, hour: 12)
    )!
}

@MainActor
private func makeLedgerStore() throws -> LedgerStore {
    LedgerStore(store: InMemoryKeyValueStore(), calendar: ledgerCalendar)
}

let ledgerStoreTests: [TestCase] = [
    TestCase(name: "settings round trip through injected storage") {
        let memory = InMemoryKeyValueStore()
        let store = SettingsStore(store: memory)
        var settings = WorkSettings.default
        settings.dailySalaryCents = 88_888

        try store.save(settings)

        try expectEqual(store.load(), settings, "settings")
    },
    TestCase(name: "corrupted settings fall back to defaults") {
        let memory = InMemoryKeyValueStore()
        memory.values[SettingsStore.storageKey] = Data("broken".utf8)

        try expectEqual(
            SettingsStore(store: memory).load(),
            WorkSettings.default,
            "fallback"
        )
    },
    TestCase(name: "calendar overrides take priority over weekdays") {
        let store = try makeLedgerStore()
        let thursday = ledgerDate(2026, 7, 30)
        let saturday = ledgerDate(2026, 8, 1)

        try expect(store.isWorkday(thursday, settings: .default), "Thursday works")
        try expect(!store.isWorkday(saturday, settings: .default), "Saturday rests")

        try store.setOverride(.rest, on: thursday)
        try store.setOverride(.work, on: saturday)

        try expect(!store.isWorkday(thursday, settings: .default), "rest wins")
        try expect(store.isWorkday(saturday, settings: .default), "work wins")
    },
    TestCase(name: "reconcile fills missed workdays exactly once") {
        let store = try makeLedgerStore()
        var settings = WorkSettings.default
        settings.trackingStartDate = ledgerDate(2026, 7, 30)
        let through = ledgerDate(2026, 8, 4)

        try store.reconcile(settings: settings, through: through)
        try store.reconcile(settings: settings, through: through)

        let records = store.allRecords()
        try expectEqual(records.count, 3, "record count")
        try expectEqual(
            records.reduce(Int64(0)) { $0 + $1.earnedCents },
            120_000,
            "settled total"
        )
    },
    TestCase(name: "manual workday is included in reconciliation") {
        let store = try makeLedgerStore()
        var settings = WorkSettings.default
        settings.trackingStartDate = ledgerDate(2026, 7, 30)
        let saturday = ledgerDate(2026, 8, 1)
        try store.setOverride(.work, on: saturday)

        try store.reconcile(
            settings: settings,
            through: ledgerDate(2026, 8, 4)
        )

        try expectEqual(store.allRecords().count, 4, "record count")
        try expectEqual(store.historicalTotalCents(), 160_000, "total")
    }
]
