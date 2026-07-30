import Foundation

protocol KeyValueStore: AnyObject {
    func data(forKey defaultName: String) -> Data?
    func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: KeyValueStore {}

enum SettingsStoreError: Error {
    case encodingFailed
}

final class SettingsStore {
    static let storageKey = "cowHorseClock.workSettings.v1"

    private let store: KeyValueStore
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        store: KeyValueStore = UserDefaults.standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.store = store
        self.encoder = encoder
        self.decoder = decoder
    }

    func load() -> WorkSettings {
        guard
            let data = store.data(forKey: Self.storageKey),
            let settings = try? decoder.decode(WorkSettings.self, from: data)
        else {
            return .default
        }
        return settings
    }

    func save(_ settings: WorkSettings) throws {
        guard let data = try? encoder.encode(settings) else {
            throw SettingsStoreError.encodingFailed
        }
        store.set(data, forKey: Self.storageKey)
    }
}
