import Foundation

struct CalendarOverride: Codable, Equatable, Identifiable {
    var dateKey: String
    var kindRawValue: String

    var id: String { dateKey }

    init(dateKey: String, kind: CalendarOverrideKind) {
        self.dateKey = dateKey
        self.kindRawValue = kind.rawValue
    }

    var kind: CalendarOverrideKind {
        get { CalendarOverrideKind(rawValue: kindRawValue) ?? .rest }
        set { kindRawValue = newValue.rawValue }
    }
}

struct DailyEarningRecord: Codable, Equatable, Identifiable {
    var dateKey: String
    var salaryCents: Int64
    var morningStart: Int
    var morningEnd: Int
    var afternoonStart: Int
    var afternoonEnd: Int
    var earnedCents: Int64
    var settledAt: Date

    var id: String { dateKey }

    init(
        dateKey: String,
        settings: WorkSettings,
        earnedCents: Int64,
        settledAt: Date
    ) {
        self.dateKey = dateKey
        self.salaryCents = settings.dailySalaryCents
        self.morningStart = settings.morning.startMinute
        self.morningEnd = settings.morning.endMinute
        self.afternoonStart = settings.afternoon.startMinute
        self.afternoonEnd = settings.afternoon.endMinute
        self.earnedCents = earnedCents
        self.settledAt = settledAt
    }
}

struct LedgerData: Codable, Equatable {
    var overrides: [CalendarOverride] = []
    var records: [DailyEarningRecord] = []
}
