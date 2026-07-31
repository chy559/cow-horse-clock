import Foundation

private let milestoneDateA = Date(timeIntervalSince1970: 100)
private let milestoneDateB = Date(timeIntervalSince1970: 200)

@MainActor
private func makeMilestoneModel(
    store: MilestoneStore = MilestoneStore(store: InMemoryKeyValueStore()),
    now: @escaping () -> Date = { Date(timeIntervalSince1970: 300) }
) -> MilestoneModel {
    MilestoneModel(store: store, now: now)
}

let milestoneTests: [TestCase] = [
    TestCase(name: "milestone categories expose matching names and icons") {
        try expectEqual(MilestoneCategory.work.title, "工作", "work title")
        try expectEqual(
            MilestoneCategory.work.systemImage,
            "briefcase.fill",
            "work icon"
        )
        try expectEqual(
            MilestoneCategory.life.systemImage,
            "house.fill",
            "life icon"
        )
        try expectEqual(
            MilestoneCategory.growth.systemImage,
            "sparkles",
            "growth icon"
        )
        try expectEqual(
            MilestoneCategory.relationship.systemImage,
            "heart.fill",
            "relationship icon"
        )
        try expectEqual(
            MilestoneCategory.health.systemImage,
            "cross.case.fill",
            "health icon"
        )
        try expectEqual(
            MilestoneCategory.other.systemImage,
            "bookmark.fill",
            "other icon"
        )
    },
    TestCase(name: "milestone model trims notes and sorts newest events first") {
        let model = makeMilestoneModel()

        try expect(
            model.add(
                date: milestoneDateA,
                note: "  搬进新家  ",
                category: .life
            ),
            "first add"
        )
        try expect(
            model.add(date: milestoneDateB, note: "升职", category: .work),
            "second add"
        )
        try expectEqual(
            model.milestones.map(\.note),
            ["升职", "搬进新家"],
            "sorted notes"
        )
    },
    TestCase(name: "milestone model rejects blank notes") {
        let model = makeMilestoneModel()

        try expect(
            !model.add(date: milestoneDateA, note: "  \n ", category: .other),
            "blank add"
        )
        try expectEqual(model.milestones.count, 0, "count")
    },
    TestCase(name: "milestone editing preserves identity and creation time") {
        let model = makeMilestoneModel()

        try expect(
            model.add(date: milestoneDateA, note: "入职", category: .work),
            "add"
        )
        let original = model.milestones[0]
        try expect(
            model.update(
                id: original.id,
                date: milestoneDateB,
                note: "  转正  ",
                category: .growth
            ),
            "update"
        )
        let updated = model.milestones[0]
        try expectEqual(updated.id, original.id, "id")
        try expectEqual(updated.createdAt, original.createdAt, "createdAt")
        try expectEqual(updated.note, "转正", "note")
        try expectEqual(updated.category, .growth, "category")
    },
    TestCase(name: "milestone delete removes persisted event") {
        let memory = InMemoryKeyValueStore()
        let store = MilestoneStore(store: memory)
        let model = makeMilestoneModel(store: store)

        try expect(
            model.add(date: milestoneDateA, note: "毕业", category: .growth),
            "add"
        )
        let id = model.milestones[0].id
        try expect(model.delete(id: id), "delete")
        try expectEqual(
            MilestoneModel(store: store).milestones.count,
            0,
            "restored count"
        )
    },
    TestCase(name: "milestones persist and corrupted data falls back empty") {
        let memory = InMemoryKeyValueStore()
        let store = MilestoneStore(store: memory)
        let model = makeMilestoneModel(store: store)

        try expect(
            model.add(
                date: milestoneDateA,
                note: "第一次旅行",
                category: .life
            ),
            "add"
        )
        try expectEqual(
            MilestoneModel(store: store).milestones.map(\.note),
            ["第一次旅行"],
            "round trip"
        )

        memory.set(Data("broken".utf8), forKey: MilestoneStore.storageKey)
        try expectEqual(
            MilestoneModel(store: store).milestones.count,
            0,
            "corrupted fallback"
        )
    }
]
