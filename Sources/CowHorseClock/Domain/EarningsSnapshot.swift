import Foundation

enum EarningsState: Equatable, Sendable {
    case beforeWork
    case workingMorning
    case lunch
    case workingAfternoon
    case finished
    case restDay
}

struct EarningsSnapshot: Equatable, Sendable {
    let earnedCents: Decimal
    let rateCentsPerSecond: Decimal
    let progress: Double
    let state: EarningsState
    let secondsUntilNextTransition: Int?

    static let zero = EarningsSnapshot(
        earnedCents: .zero,
        rateCentsPerSecond: .zero,
        progress: 0,
        state: .restDay,
        secondsUntilNextTransition: nil
    )
}
