import Combine
import Foundation

@MainActor
final class MilestoneModel: ObservableObject {
    @Published private(set) var milestones: [Milestone]

    private let store: MilestoneStore
    private let now: () -> Date

    init(
        store: MilestoneStore = MilestoneStore(),
        now: @escaping () -> Date = Date.init
    ) {
        self.store = store
        self.now = now
        self.milestones = Self.sorted(store.load())
    }

    @discardableResult
    func add(
        date: Date,
        note: String,
        category: MilestoneCategory
    ) -> Bool {
        let cleanedNote = cleaned(note)
        guard !cleanedNote.isEmpty else { return false }

        let milestone = Milestone(
            id: UUID(),
            date: date,
            note: cleanedNote,
            category: category,
            createdAt: now()
        )
        return replaceIfPersisted(milestones + [milestone])
    }

    @discardableResult
    func update(
        id: UUID,
        date: Date,
        note: String,
        category: MilestoneCategory
    ) -> Bool {
        let cleanedNote = cleaned(note)
        guard
            !cleanedNote.isEmpty,
            let index = milestones.firstIndex(where: { $0.id == id })
        else {
            return false
        }

        var candidate = milestones
        candidate[index].date = date
        candidate[index].note = cleanedNote
        candidate[index].category = category
        return replaceIfPersisted(candidate)
    }

    @discardableResult
    func delete(id: UUID) -> Bool {
        guard milestones.contains(where: { $0.id == id }) else {
            return false
        }
        return replaceIfPersisted(milestones.filter { $0.id != id })
    }

    private func cleaned(_ note: String) -> String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func replaceIfPersisted(_ candidate: [Milestone]) -> Bool {
        let sortedMilestones = Self.sorted(candidate)
        guard store.save(sortedMilestones) else { return false }
        milestones = sortedMilestones
        return true
    }

    private static func sorted(_ milestones: [Milestone]) -> [Milestone] {
        milestones.sorted { left, right in
            if left.date != right.date {
                return left.date > right.date
            }
            return left.createdAt > right.createdAt
        }
    }
}
