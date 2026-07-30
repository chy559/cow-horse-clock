import Foundation

struct TimeRange: Codable, Equatable, Sendable {
    var startMinute: Int
    var endMinute: Int

    var durationSeconds: Int {
        max(0, endMinute - startMinute) * 60
    }
}

enum SettingsValidationError: Equatable, Sendable {
    case negativeSalary
    case invalidMorningRange
    case invalidAfternoonRange
    case rangesOverlap
    case noWorkday
}

enum CalendarOverrideKind: String, Codable, CaseIterable, Sendable {
    case rest
    case work
}

struct WorkSettings: Codable, Equatable, Sendable {
    var dailySalaryCents: Int64
    var morning: TimeRange
    var afternoon: TimeRange
    var defaultWeekdays: Set<Int>
    var launchAtLogin: Bool
    var trackingStartDate: Date?
    var lastReconciledDate: Date?

    static let `default` = WorkSettings(
        dailySalaryCents: 40_000,
        morning: TimeRange(startMinute: 9 * 60, endMinute: 12 * 60),
        afternoon: TimeRange(startMinute: 13 * 60 + 30, endMinute: 18 * 60),
        defaultWeekdays: [2, 3, 4, 5, 6],
        launchAtLogin: false,
        trackingStartDate: nil,
        lastReconciledDate: nil
    )

    var validationErrors: [SettingsValidationError] {
        var errors: [SettingsValidationError] = []

        if dailySalaryCents < 0 {
            errors.append(.negativeSalary)
        }
        if morning.endMinute <= morning.startMinute {
            errors.append(.invalidMorningRange)
        }
        if afternoon.endMinute <= afternoon.startMinute {
            errors.append(.invalidAfternoonRange)
        }
        if morning.endMinute > afternoon.startMinute {
            errors.append(.rangesOverlap)
        }
        if defaultWeekdays.isEmpty {
            errors.append(.noWorkday)
        }

        return errors
    }
}
