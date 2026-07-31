# 人生大事 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增一个与薪资、账本和专注计时隔离，可按日期与分类新增、筛选、编辑和删除人生大事的独立页面。

**Architecture:** `MilestoneStore` 使用独立 UserDefaults 键保存 Codable 记录，`MilestoneModel` 负责验证、持久化和稳定排序，`MilestoneView` 只消费该模型。现有 `AppModel` 只扩展 `.milestones` 导航枚举，不持有人生大事数据。

**Tech Stack:** Swift 6、SwiftUI、Foundation、macOS 14、自定义 Swift 测试运行器。

## Global Constraints

- 大事状态不得依赖 `AppModel`、`LedgerStore`、`EarningsEngine` 或 `FocusTimerModel`。
- 每条记录必须包含 UUID、日期、非空描述、固定分类和创建时间。
- 固定分类为工作、生活、成长、关系、健康、其他，并使用规格中的 SF Symbols 图标。
- 存储键必须为 `cowHorseClock.milestones.v1`。
- 页面固定为 360×560，列表卡片采用 18 圆角、柔和渐变、轻微阴影和悬浮凸起。
- 支持新增、编辑、删除和分类筛选，不加入提醒、附件、地点或云同步。
- 禁止调用 `pdftotext`。

---

### Task 1: 实现人生大事数据、持久化与模型

**Files:**
- Create: `Sources/CowHorseClock/Persistence/MilestoneStore.swift`
- Create: `Sources/CowHorseClock/Features/Milestones/MilestoneModel.swift`
- Create: `Tests/CowHorseClockTests/MilestoneTests.swift`
- Modify: `Tests/CowHorseClockTests/AllTests.swift`
- Modify: `scripts/test.sh`

**Interfaces:**
- Produces: `MilestoneCategory`、`Milestone`、`MilestoneStore`、`MilestoneModel`
- `MilestoneModel` operations: `add(date:note:category:) -> Bool`、`update(id:date:note:category:) -> Bool`、`delete(id:) -> Bool`

- [ ] **Step 1: 写失败的领域与模型测试并接入运行器**

创建 `MilestoneTests.swift`，使用 `InMemoryKeyValueStore`，覆盖以下真实行为：

```swift
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
        try expectEqual(MilestoneCategory.work.systemImage, "briefcase.fill", "work icon")
        try expectEqual(MilestoneCategory.life.systemImage, "house.fill", "life icon")
        try expectEqual(MilestoneCategory.growth.systemImage, "sparkles", "growth icon")
        try expectEqual(MilestoneCategory.relationship.systemImage, "heart.fill", "relationship icon")
        try expectEqual(MilestoneCategory.health.systemImage, "cross.case.fill", "health icon")
        try expectEqual(MilestoneCategory.other.systemImage, "bookmark.fill", "other icon")
    },
    TestCase(name: "milestone model trims notes and sorts newest events first") {
        let model = makeMilestoneModel()
        try expect(model.add(date: milestoneDateA, note: "  搬进新家  ", category: .life), "first add")
        try expect(model.add(date: milestoneDateB, note: "升职", category: .work), "second add")
        try expectEqual(model.milestones.map(\.note), ["升职", "搬进新家"], "sorted notes")
    },
    TestCase(name: "milestone model rejects blank notes") {
        let model = makeMilestoneModel()
        try expect(!model.add(date: milestoneDateA, note: "  \n ", category: .other), "blank add")
        try expectEqual(model.milestones.count, 0, "count")
    },
    TestCase(name: "milestone editing preserves identity and creation time") {
        let model = makeMilestoneModel()
        try expect(model.add(date: milestoneDateA, note: "入职", category: .work), "add")
        let original = model.milestones[0]
        try expect(model.update(id: original.id, date: milestoneDateB, note: "  转正  ", category: .growth), "update")
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
        try expect(model.add(date: milestoneDateA, note: "毕业", category: .growth), "add")
        let id = model.milestones[0].id
        try expect(model.delete(id: id), "delete")
        try expectEqual(MilestoneModel(store: store).milestones.count, 0, "restored count")
    },
    TestCase(name: "milestones persist independently and corrupted data falls back empty") {
        let memory = InMemoryKeyValueStore()
        let store = MilestoneStore(store: memory)
        let model = makeMilestoneModel(store: store)
        try expect(model.add(date: milestoneDateA, note: "第一次旅行", category: .life), "add")
        try expectEqual(MilestoneModel(store: store).milestones.map(\.note), ["第一次旅行"], "round trip")
        memory.set(Data("broken".utf8), forKey: MilestoneStore.storageKey)
        try expectEqual(MilestoneModel(store: store).milestones.count, 0, "corrupted fallback")
    }
]
```

在 `AllTests.swift` 末尾加入 `+ milestoneTests`；在 `scripts/test.sh` 编译参数中加入两个生产文件和 `MilestoneTests.swift`。

- [ ] **Step 2: 运行测试并确认红灯**

Run: `bash scripts/test.sh`

Expected: FAIL，原因是 `MilestoneCategory`、`MilestoneStore` 和 `MilestoneModel` 尚未定义。

- [ ] **Step 3: 实现领域类型与独立存储**

在 `MilestoneStore.swift` 定义：

```swift
import Foundation

enum MilestoneCategory: String, Codable, CaseIterable, Equatable, Identifiable {
    case work, life, growth, relationship, health, other
    var id: String { rawValue }

    var title: String {
        switch self {
        case .work: "工作"
        case .life: "生活"
        case .growth: "成长"
        case .relationship: "关系"
        case .health: "健康"
        case .other: "其他"
        }
    }

    var systemImage: String {
        switch self {
        case .work: "briefcase.fill"
        case .life: "house.fill"
        case .growth: "sparkles"
        case .relationship: "heart.fill"
        case .health: "cross.case.fill"
        case .other: "bookmark.fill"
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
        guard let data = store.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([Milestone].self, from: data)
        else { return [] }
        return decoded
    }

    func save(_ milestones: [Milestone]) -> Bool {
        guard let data = try? JSONEncoder().encode(milestones) else { return false }
        store.set(data, forKey: Self.storageKey)
        return true
    }
}
```

`title` 和 `systemImage` 必须穷举所有分类，不使用默认分支。

- [ ] **Step 4: 实现验证、排序和增删改模型**

在 `MilestoneModel.swift` 实现：

```swift
import Combine
import Foundation

@MainActor
final class MilestoneModel: ObservableObject {
    @Published private(set) var milestones: [Milestone]
    private let store: MilestoneStore
    private let now: () -> Date

    init(store: MilestoneStore = MilestoneStore(), now: @escaping () -> Date = Date.init) {
        self.store = store
        self.now = now
        self.milestones = Self.sorted(store.load())
    }

    @discardableResult
    func add(date: Date, note: String, category: MilestoneCategory) -> Bool {
        let cleaned = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return false }
        let candidate = milestones + [Milestone(id: UUID(), date: date, note: cleaned, category: category, createdAt: now())]
        return replaceIfPersisted(candidate)
    }

    @discardableResult
    func update(id: UUID, date: Date, note: String, category: MilestoneCategory) -> Bool {
        let cleaned = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, let index = milestones.firstIndex(where: { $0.id == id }) else { return false }
        var candidate = milestones
        candidate[index].date = date
        candidate[index].note = cleaned
        candidate[index].category = category
        return replaceIfPersisted(candidate)
    }

    @discardableResult
    func delete(id: UUID) -> Bool {
        guard milestones.contains(where: { $0.id == id }) else { return false }
        return replaceIfPersisted(milestones.filter { $0.id != id })
    }
}
```

`replaceIfPersisted(_:)` 先排序候选数据，只有 `store.save` 返回真时才发布；排序按 `date` 倒序，同日按 `createdAt` 倒序。

- [ ] **Step 5: 运行测试并提交**

Run: `bash scripts/test.sh`

Expected: 原有 42 项与新增 6 项全部通过，图标契约通过。

Commit: `feat: add persistent life milestones model`

---

### Task 2: 添加独立导航与仪表盘入口

**Files:**
- Create: `Sources/CowHorseClock/Features/Milestones/MilestoneView.swift`
- Create: `Tests/CowHorseClockTests/MilestoneSourceTests.swift`
- Modify: `Sources/CowHorseClock/AppModel.swift`
- Modify: `Sources/CowHorseClock/CowHorseClockApp.swift`
- Modify: `Sources/CowHorseClock/Features/RootPopoverView.swift`
- Modify: `Sources/CowHorseClock/Features/Dashboard/DashboardView.swift`
- Modify: `Tests/CowHorseClockTests/AllTests.swift`
- Modify: `scripts/test.sh`

**Interfaces:**
- Consumes: `MilestoneModel`
- Produces: `AppRoute.milestones`、独立环境注入、仪表盘旗帜入口、最小 `MilestoneView`

- [ ] **Step 1: 写失败的导航源码测试**

创建 `MilestoneSourceTests.swift`，读取源码并断言：

```swift
try expect(appModelSource.contains("case milestones"), "app route should include milestones")
try expect(rootSource.contains("case .milestones:") && rootSource.contains("MilestoneView("), "root should route to milestones")
try expect(dashboardSource.contains("model.route = .milestones") && dashboardSource.contains("Image(systemName: \"flag.fill\")"), "dashboard should expose milestones")
try expect(appSource.contains("@StateObject private var milestoneModel") && appSource.contains(".environmentObject(milestoneModel)"), "app should inject milestone model")
```

接入 `AllTests.swift` 与 `scripts/test.sh`。

- [ ] **Step 2: 运行测试并确认红灯**

Run: `bash scripts/test.sh`

Expected: FAIL，输出 `app route should include milestones`。

- [ ] **Step 3: 添加路由、环境模型和最小页面**

- `AppRoute` 添加 `case milestones`。
- `CowHorseClockApp` 添加 `@StateObject private var milestoneModel = MilestoneModel()` 并注入。
- `RootPopoverView` 的 `.milestones` 分支创建 `MilestoneView(onBack:)`，返回时设置 `.dashboard`。
- 创建可编译的 `MilestoneView`，使用 `@EnvironmentObject private var milestones: MilestoneModel`，固定 360×560 并显示 `LIFE EVENTS`。

- [ ] **Step 4: 添加仪表盘入口**

在专注按钮左侧添加：

```swift
Button {
    model.route = .milestones
} label: {
    Image(systemName: "flag.fill")
        .frame(width: 30, height: 30)
        .softPunchCard(fill: .punchMint, radius: 12)
}
.buttonStyle(.plain)
.hoverLift(.compact)
.help("人生大事")
```

- [ ] **Step 5: 运行测试并提交**

Run: `bash scripts/test.sh && bash scripts/build-app.sh`

Expected: 49 项测试通过、图标契约通过、Release 构建成功。

Commit: `feat: add life milestones navigation`

---

### Task 3: 构建人生大事列表和编辑页面

**Files:**
- Modify: `Sources/CowHorseClock/Features/Milestones/MilestoneView.swift`
- Modify: `Tests/CowHorseClockTests/MilestoneSourceTests.swift`

**Interfaces:**
- Consumes: `MilestoneModel`、`MilestoneCategory`、`onBack: () -> Void`
- Produces: 分类筛选列表、新增/编辑/删除交互

- [ ] **Step 1: 写失败的页面源码测试**

在 `MilestoneSourceTests.swift` 追加断言：

```swift
let source = try milestoneSource("Sources/CowHorseClock/Features/Milestones/MilestoneView.swift")
try expect(source.contains("ForEach(MilestoneCategory.allCases)"), "page should expose all categories")
try expect(source.contains("milestones.add("), "page should add")
try expect(source.contains("milestones.update("), "page should edit")
try expect(source.contains("milestones.delete("), "page should delete")
try expect(source.contains("DatePicker("), "editor should select a date")
try expect(source.contains("TextEditor(text: $draftNote)"), "editor should accept a description")
try expect(!source.contains("snapshot") && !source.contains("ledgerStore") && !source.contains("FocusTimerModel"), "milestone page should remain independent")
```

- [ ] **Step 2: 运行测试并确认红灯**

Run: `bash scripts/test.sh`

Expected: FAIL，输出 `page should expose all categories`。

- [ ] **Step 3: 实现列表、统计和分类筛选**

页面状态：

```swift
@State private var selectedCategory: MilestoneCategory?
@State private var editingMilestone: Milestone?
@State private var isCreating = false
@State private var draftDate = Date()
@State private var draftCategory = MilestoneCategory.life
@State private var draftNote = ""
```

列表模式必须实现：

- 顶部返回按钮、`LIFE EVENTS` 标签和新增按钮。
- “全部记录”与“今年”两个 18 圆角统计卡。
- 横向“全部”加 `MilestoneCategory.allCases` 筛选按钮。
- `ScrollView` 中显示过滤后的记录卡；卡片包含分类图标、标题、中文日期和描述。
- 点击卡片载入草稿并进入编辑模式。
- 空状态使用 `flag.checkered` 图标与“还没有写下人生大事”。

- [ ] **Step 4: 实现新增、编辑和删除模式**

编辑模式必须实现：

- 返回按钮只取消编辑并回到列表。
- `DatePicker("发生日期", selection: $draftDate, displayedComponents: .date)`。
- 六个分类按钮，图标来自 `category.systemImage`。
- `TextEditor(text: $draftNote)` 多行输入。
- 保存按钮在清理后的描述为空时禁用。
- 新增调用 `milestones.add(...)`；编辑调用 `milestones.update(...)`，成功后回到列表。
- 编辑已有记录时显示“删除这件大事”，调用 `milestones.delete(id:)` 后回到列表。
- 所有卡片使用 `softPunchCard(..., radius: 18)` 与 `.hoverLift()`，操作按钮圆角为 12 或 14。

- [ ] **Step 5: 运行测试、构建并提交**

Run: `bash scripts/test.sh && bash scripts/build-app.sh`

Expected: 50 项测试通过、图标契约通过、Release 构建成功。

Commit: `feat: add life milestones page`

---

### Task 4: 视觉与交付验收

**Files:**
- No production file required unless visual verification reveals a defect.

**Interfaces:**
- Consumes: 完成的人生大事页面
- Produces: 已验收的最终 `.app`

- [ ] **Step 1: 渲染列表和编辑状态**

使用实际 `MilestoneView`、`MilestoneModel` 与内存存储分别渲染包含三条不同分类记录的列表状态和新建状态，输出 720×1120 PNG。

- [ ] **Step 2: 检查并修复视觉缺陷**

确认标题、统计卡、筛选、记录描述、日期、分类图标、编辑控件和底部按钮均在 360×560 内完整显示；若发现问题，先写失败的源码或模型测试再修复。

- [ ] **Step 3: 完成最终验证**

Run:

```bash
bash scripts/test.sh
bash scripts/build-app.sh
plutil -lint dist/CowHorseClock.app/Contents/Info.plist
codesign --verify --deep --strict dist/CowHorseClock.app
git diff --check
```

Expected: 50 项测试全部通过、图标契约通过、Release 构建成功、plist 与签名验证成功、无空白错误。
