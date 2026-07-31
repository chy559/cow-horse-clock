import Foundation

enum FocusTimerPhase: String, Codable, Equatable {
    case idle
    case running
    case paused
    case completed
}

struct FocusTimerRecord: Codable, Equatable {
    var selectedMinutes: Int
    var phase: FocusTimerPhase
    var remainingSeconds: TimeInterval
    var endDate: Date?

    static let initial = FocusTimerRecord(
        selectedMinutes: 25,
        phase: .idle,
        remainingSeconds: 1_500,
        endDate: nil
    )
}

final class FocusTimerStore {
    static let storageKey = "cowHorseClock.focusTimer.v1"

    private let store: KeyValueStore

    init(store: KeyValueStore = UserDefaults.standard) {
        self.store = store
    }

    func load() -> FocusTimerRecord {
        guard
            let data = store.data(forKey: Self.storageKey),
            let record = try? JSONDecoder().decode(FocusTimerRecord.self, from: data)
        else {
            return .initial
        }
        return record
    }

    func save(_ record: FocusTimerRecord) {
        guard let data = try? JSONEncoder().encode(record) else { return }
        store.set(data, forKey: Self.storageKey)
    }
}
