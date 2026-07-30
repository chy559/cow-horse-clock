import Foundation

struct MonthSummary {
    let monthStart: Date
    let settledCents: Int64
    let records: [DailyEarningRecord]
}

@MainActor
final class LedgerStore {
    static let storageKey = "cowHorseClock.ledger.v1"

    let calendar: Calendar
    private let store: KeyValueStore
    private var data: LedgerData

    init(
        store: KeyValueStore = UserDefaults.standard,
        calendar: Calendar = .current
    ) {
        self.store = store
        self.calendar = calendar
        if
            let storedData = store.data(forKey: Self.storageKey),
            let decoded = try? JSONDecoder().decode(LedgerData.self, from: storedData)
        {
            self.data = decoded
        } else {
            self.data = LedgerData()
        }
    }

    func dateKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    func date(fromKey key: String) -> Date? {
        let values = key.split(separator: "-").compactMap { Int($0) }
        guard values.count == 3 else { return nil }
        return calendar.date(
            from: DateComponents(year: values[0], month: values[1], day: values[2])
        )
    }

    func overrideKind(on date: Date) -> CalendarOverrideKind? {
        let key = dateKey(for: date)
        return data.overrides.first(where: { $0.dateKey == key })?.kind
    }

    func setOverride(_ kind: CalendarOverrideKind?, on date: Date) throws {
        let key = dateKey(for: date)
        data.overrides.removeAll(where: { $0.dateKey == key })
        if let kind {
            data.overrides.append(CalendarOverride(dateKey: key, kind: kind))
        }
        data.overrides.sort { $0.dateKey < $1.dateKey }
        try persist()
    }

    func allOverrides() -> [CalendarOverride] {
        data.overrides.sorted { $0.dateKey < $1.dateKey }
    }

    func isWorkday(_ date: Date, settings: WorkSettings) -> Bool {
        if let override = overrideKind(on: date) {
            return override == .work
        }
        return settings.defaultWeekdays.contains(calendar.component(.weekday, from: date))
    }

    func reconcile(settings: WorkSettings, through date: Date) throws {
        guard let trackingStartDate = settings.trackingStartDate else { return }

        let endDate = calendar.startOfDay(for: date)
        var cursor = calendar.startOfDay(for: trackingStartDate)
        var existingKeys = Set(data.records.map(\.dateKey))

        while cursor < endDate {
            let key = dateKey(for: cursor)
            if !existingKeys.contains(key), isWorkday(cursor, settings: settings) {
                data.records.append(
                    DailyEarningRecord(
                        dateKey: key,
                        settings: settings,
                        earnedCents: settings.dailySalaryCents,
                        settledAt: endDate
                    )
                )
                existingKeys.insert(key)
            }

            guard
                let nextDate = calendar.date(byAdding: .day, value: 1, to: cursor)
            else {
                break
            }
            cursor = nextDate
        }

        data.records.sort { $0.dateKey > $1.dateKey }
        try persist()
    }

    func allRecords() -> [DailyEarningRecord] {
        data.records.sorted { $0.dateKey > $1.dateKey }
    }

    func historicalTotalCents() -> Int64 {
        data.records.reduce(Int64(0)) { $0 + $1.earnedCents }
    }

    func monthSummary(containing date: Date) -> MonthSummary {
        let components = calendar.dateComponents([.year, .month], from: date)
        let start = calendar.date(from: components) ?? calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        let records = data.records.filter { record in
            guard let recordDate = self.date(fromKey: record.dateKey) else {
                return false
            }
            return recordDate >= start && recordDate < end
        }
        return MonthSummary(
            monthStart: start,
            settledCents: records.reduce(Int64(0)) { $0 + $1.earnedCents },
            records: records.sorted { $0.dateKey > $1.dateKey }
        )
    }

    private func persist() throws {
        let encoded = try JSONEncoder().encode(data)
        store.set(encoded, forKey: Self.storageKey)
    }
}
