import Foundation

let moneyFormatterTests: [TestCase] = [
    TestCase(name: "yuan formatter keeps two fraction digits") {
        try expectEqual(
            MoneyFormatter.yuan(cents: Decimal(28_642)),
            "¥286.42",
            "amount"
        )
        try expectEqual(
            MoneyFormatter.yuan(cents: Decimal(864_000)),
            "¥8,640.00",
            "grouped amount"
        )
    },
    TestCase(name: "rate formatter shows sub-cent earnings") {
        try expectEqual(
            MoneyFormatter.rate(centsPerSecond: Decimal(string: "1.48148")!),
            "¥0.0148",
            "rate"
        )
    },
    TestCase(name: "duration formatter uses clock notation") {
        try expectEqual(MoneyFormatter.duration(seconds: 8_316), "02:18:36", "time")
        try expectEqual(MoneyFormatter.duration(seconds: nil), "--:--:--", "empty")
    }
]
