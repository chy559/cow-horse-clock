import AppKit
import Combine
import Foundation

@MainActor
final class FocusTimerModel: ObservableObject {
    static let minuteRange = 5...180
    static let minuteStep = 5

    @Published private(set) var selectedMinutes: Int
    @Published private(set) var phase: FocusTimerPhase
    @Published private(set) var remainingSeconds: TimeInterval
    @Published private(set) var endDate: Date?

    private let store: FocusTimerStore
    private let now: () -> Date
    private let onCompleted: () -> Void
    private var ticker: AnyCancellable?

    init(
        store: FocusTimerStore = FocusTimerStore(),
        now: @escaping () -> Date = Date.init,
        startsTimer: Bool = true,
        onCompleted: @escaping () -> Void = { NSSound.beep() }
    ) {
        let record = store.load()
        let minutes = Self.clampedMinutes(record.selectedMinutes)

        self.store = store
        self.now = now
        self.onCompleted = onCompleted
        self.selectedMinutes = minutes
        self.phase = record.phase
        self.remainingSeconds = max(0, record.remainingSeconds)
        self.endDate = record.endDate

        normalizeLoadedState()
        refresh(at: now(), notifyCompletion: false)

        if startsTimer {
            ticker = Timer.publish(every: 0.25, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] date in
                    Task { @MainActor in
                        self?.refresh(at: date)
                    }
                }
        }
    }

    var progress: Double {
        let total = Double(selectedMinutes * 60)
        guard total > 0 else { return 0 }
        return min(1, max(0, 1 - remainingSeconds / total))
    }

    func select(minutes: Int) {
        guard phase == .idle || phase == .completed else { return }
        selectedMinutes = Self.clampedMinutes(minutes)
        phase = .idle
        remainingSeconds = totalSeconds
        endDate = nil
        persist()
    }

    func adjustMinutes(by minutes: Int) {
        select(minutes: selectedMinutes + minutes)
    }

    func start() {
        start(at: now())
    }

    func start(at date: Date) {
        guard phase == .idle || phase == .completed else { return }
        remainingSeconds = totalSeconds
        endDate = date.addingTimeInterval(remainingSeconds)
        phase = .running
        persist()
    }

    func pause() {
        pause(at: now())
    }

    func pause(at date: Date) {
        guard phase == .running else { return }
        updateRemaining(at: date)
        guard remainingSeconds > 0 else {
            complete(notify: true)
            return
        }
        phase = .paused
        endDate = nil
        persist()
    }

    func resume() {
        resume(at: now())
    }

    func resume(at date: Date) {
        guard phase == .paused, remainingSeconds > 0 else { return }
        endDate = date.addingTimeInterval(remainingSeconds)
        phase = .running
        persist()
    }

    func reset() {
        phase = .idle
        remainingSeconds = totalSeconds
        endDate = nil
        persist()
    }

    func refresh(at date: Date) {
        refresh(at: date, notifyCompletion: true)
    }

    private var totalSeconds: TimeInterval {
        TimeInterval(selectedMinutes * 60)
    }

    private static func clampedMinutes(_ minutes: Int) -> Int {
        min(minuteRange.upperBound, max(minuteRange.lowerBound, minutes))
    }

    private func normalizeLoadedState() {
        switch phase {
        case .idle:
            remainingSeconds = totalSeconds
            endDate = nil
        case .running:
            if endDate == nil {
                phase = .idle
                remainingSeconds = totalSeconds
            }
        case .paused:
            remainingSeconds = min(totalSeconds, remainingSeconds)
            endDate = nil
        case .completed:
            remainingSeconds = 0
            endDate = nil
        }
    }

    private func refresh(at date: Date, notifyCompletion: Bool) {
        guard phase == .running else { return }
        updateRemaining(at: date)
        if remainingSeconds <= 0 {
            complete(notify: notifyCompletion)
        }
    }

    private func updateRemaining(at date: Date) {
        remainingSeconds = max(0, endDate?.timeIntervalSince(date) ?? 0)
    }

    private func complete(notify: Bool) {
        guard phase == .running else { return }
        phase = .completed
        remainingSeconds = 0
        endDate = nil
        persist()
        if notify {
            onCompleted()
        }
    }

    private func persist() {
        store.save(
            FocusTimerRecord(
                selectedMinutes: selectedMinutes,
                phase: phase,
                remainingSeconds: remainingSeconds,
                endDate: endDate
            )
        )
    }
}
