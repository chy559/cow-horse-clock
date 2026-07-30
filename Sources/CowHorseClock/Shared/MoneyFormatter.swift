import Foundation

enum MoneyFormatter {
    static func yuan(cents: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        let yuan = cents / Decimal(100)
        let value = formatter.string(from: NSDecimalNumber(decimal: yuan)) ?? "0.00"
        return "¥\(value)"
    }

    static func rate(centsPerSecond: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = 4
        formatter.usesGroupingSeparator = false
        let yuan = centsPerSecond / Decimal(100)
        let value = formatter.string(from: NSDecimalNumber(decimal: yuan)) ?? "0.0000"
        return "¥\(value)"
    }

    static func duration(seconds: Int?) -> String {
        guard let seconds else { return "--:--:--" }
        let bounded = max(0, seconds)
        let hours = bounded / 3_600
        let minutes = (bounded % 3_600) / 60
        let remainder = bounded % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainder)
    }
}
