import Foundation

enum EarningsEngine {
    static func snapshot(
        at now: Date,
        settings: WorkSettings,
        isWorkday: Bool,
        calendar: Calendar = .current
    ) -> EarningsSnapshot {
        guard isWorkday else {
            return .zero
        }

        let totalSeconds =
            settings.morning.durationSeconds + settings.afternoon.durationSeconds
        guard totalSeconds > 0 else {
            return .zero
        }

        let time = calendar.dateComponents([.hour, .minute, .second], from: now)
        let secondsIntoDay =
            max(0, time.hour ?? 0) * 3_600
            + max(0, time.minute ?? 0) * 60
            + max(0, time.second ?? 0)

        let morningStart = settings.morning.startMinute * 60
        let morningEnd = settings.morning.endMinute * 60
        let afternoonStart = settings.afternoon.startMinute * 60
        let afternoonEnd = settings.afternoon.endMinute * 60

        let elapsedSeconds: Int
        let state: EarningsState
        let secondsUntilNextTransition: Int?

        switch secondsIntoDay {
        case ..<morningStart:
            elapsedSeconds = 0
            state = .beforeWork
            secondsUntilNextTransition = morningStart - secondsIntoDay
        case morningStart..<morningEnd:
            elapsedSeconds = secondsIntoDay - morningStart
            state = .workingMorning
            secondsUntilNextTransition = morningEnd - secondsIntoDay
        case morningEnd..<afternoonStart:
            elapsedSeconds = settings.morning.durationSeconds
            state = .lunch
            secondsUntilNextTransition = afternoonStart - secondsIntoDay
        case afternoonStart..<afternoonEnd:
            elapsedSeconds =
                settings.morning.durationSeconds
                + secondsIntoDay - afternoonStart
            state = .workingAfternoon
            secondsUntilNextTransition = afternoonEnd - secondsIntoDay
        default:
            elapsedSeconds = totalSeconds
            state = .finished
            secondsUntilNextTransition = nil
        }

        let boundedElapsed = min(totalSeconds, max(0, elapsedSeconds))
        let rate = Decimal(settings.dailySalaryCents) / Decimal(totalSeconds)
        let earned = min(
            Decimal(settings.dailySalaryCents),
            max(
                .zero,
                Decimal(settings.dailySalaryCents)
                    * Decimal(boundedElapsed)
                    / Decimal(totalSeconds)
            )
        )

        return EarningsSnapshot(
            earnedCents: earned,
            rateCentsPerSecond: rate,
            progress: Double(boundedElapsed) / Double(totalSeconds),
            state: state,
            secondsUntilNextTransition: secondsUntilNextTransition
        )
    }
}
