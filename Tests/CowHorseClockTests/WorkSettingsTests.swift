let workSettingsTests: [TestCase] = [
    TestCase(name: "default settings are valid") {
        let value = WorkSettings.default

        try expectEqual(value.dailySalaryCents, 40_000, "daily salary")
        try expectEqual(
            value.morning,
            TimeRange(startMinute: 9 * 60, endMinute: 12 * 60),
            "morning range"
        )
        try expectEqual(
            value.afternoon,
            TimeRange(startMinute: 13 * 60 + 30, endMinute: 18 * 60),
            "afternoon range"
        )
        try expectEqual(value.defaultWeekdays, [2, 3, 4, 5, 6], "weekdays")
        try expect(value.validationErrors.isEmpty, "defaults should be valid")
    },
    TestCase(name: "overlapping ranges are rejected") {
        var value = WorkSettings.default
        value.afternoon = TimeRange(startMinute: 11 * 60 + 40, endMinute: 18 * 60)

        try expectEqual(value.validationErrors, [.rangesOverlap], "errors")
    },
    TestCase(name: "negative salary is rejected") {
        var value = WorkSettings.default
        value.dailySalaryCents = -1

        try expectEqual(value.validationErrors, [.negativeSalary], "errors")
    },
    TestCase(name: "reversed morning range is rejected") {
        var value = WorkSettings.default
        value.morning = TimeRange(startMinute: 12 * 60, endMinute: 9 * 60)

        try expectEqual(value.validationErrors, [.invalidMorningRange], "errors")
    },
    TestCase(name: "at least one default workday is required") {
        var value = WorkSettings.default
        value.defaultWeekdays = []

        try expectEqual(value.validationErrors, [.noWorkday], "errors")
    }
]
