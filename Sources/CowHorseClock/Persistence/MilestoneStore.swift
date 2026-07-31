import Foundation

enum MilestoneCategory: String, Codable, CaseIterable, Equatable, Identifiable {
    case work
    case life
    case growth
    case relationship
    case health
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .work:
            "工作"
        case .life:
            "生活"
        case .growth:
            "成长"
        case .relationship:
            "关系"
        case .health:
            "健康"
        case .other:
            "其他"
        }
    }

    var systemImage: String {
        switch self {
        case .work:
            "briefcase.fill"
        case .life:
            "house.fill"
        case .growth:
            "sparkles"
        case .relationship:
            "heart.fill"
        case .health:
            "cross.case.fill"
        case .other:
            "bookmark.fill"
        }
    }
}

struct Milestone: Codable, Equatable, Identifiable {
    let id: UUID
    var date: Date
    var note: String
    var category: MilestoneCategory
    let createdAt: Date
}

final class MilestoneStore {
    static let storageKey = "cowHorseClock.milestones.v1"

    private let store: KeyValueStore

    init(store: KeyValueStore = UserDefaults.standard) {
        self.store = store
    }

    func load() -> [Milestone] {
        guard
            let data = store.data(forKey: Self.storageKey),
            let milestones = try? JSONDecoder().decode([Milestone].self, from: data)
        else {
            return []
        }
        return milestones
    }

    @discardableResult
    func save(_ milestones: [Milestone]) -> Bool {
        guard let data = try? JSONEncoder().encode(milestones) else {
            return false
        }
        store.set(data, forKey: Self.storageKey)
        return true
    }
}
