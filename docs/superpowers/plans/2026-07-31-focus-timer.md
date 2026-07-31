# 专注时间 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增与薪资和账本状态隔离、可设置时长、可暂停恢复并能跨弹窗收起和应用重启继续的专注倒计时页面。

**Architecture:** `FocusTimerStore` 使用独立 UserDefaults 键持久化专注记录，`FocusTimerModel` 使用绝对结束时间实现状态机和倒计时，`FocusTimerView` 只消费专注模型。现有 `AppModel` 仅扩展一个 `.focus` 导航枚举值，不持有任何专注数据。

**Tech Stack:** Swift 6、SwiftUI、Combine、AppKit、macOS 14、自定义 Swift 测试运行器。

## Global Constraints

- 专注状态不得依赖 `AppModel`、`LedgerStore` 或 `EarningsEngine`。
- 默认 25 分钟，范围 `5...180` 分钟，按 5 分钟调整。
- 快捷值为 `15`、`25`、`45`、`60` 分钟。
- 使用绝对 `endDate` 计算运行中剩余时间。
- 页面切换、弹窗收起和应用重启后保持正确状态。
- 不读取薪资，不写账本，不改变现有仪表盘倒计时。
- 禁止调用 `pdftotext`。

---

### Task 1: 实现独立专注状态机与持久化

**Files:**
- Create: `Sources/CowHorseClock/Persistence/FocusTimerStore.swift`
- Create: `Sources/CowHorseClock/Features/Focus/FocusTimerModel.swift`
- Create: `Tests/CowHorseClockTests/FocusTimerTests.swift`
- Modify: `Tests/CowHorseClockTests/AllTests.swift`
- Modify: `scripts/test.sh`

**Interfaces:**
- Produces: `FocusTimerPhase`、`FocusTimerRecord`、`FocusTimerStore`、`FocusTimerModel`
- `FocusTimerModel` public operations: `select(minutes:)`、`adjustMinutes(by:)`、`start()`/`start(at:)`、`pause()`/`pause(at:)`、`resume()`/`resume(at:)`、`reset()`、`refresh(at:)`

- [ ] **Step 1: 写失败的模型测试并接入运行器**

创建 `FocusTimerTests.swift`，覆盖：

```swift
private let focusCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    return calendar
}()

private func focusDate(_ hour: Int, _ minute: Int = 0) -> Date {
    focusCalendar.date(
        from: DateComponents(
            year: 2026,
            month: 7,
            day: 31,
            hour: hour,
            minute: minute
        )
    )!
}

@MainActor
private func makeFocusModel(
    onCompleted: @escaping () -> Void = {}
) -> FocusTimerModel {
    FocusTimerModel(
        store: FocusTimerStore(store: InMemoryKeyValueStore()),
        now: { focusDate(10, 0) },
        startsTimer: false,
        onCompleted: onCompleted
    )
}

TestCase(name: "focus timer defaults to a 25 minute idle session") {
    let model = FocusTimerModel(
        store: FocusTimerStore(store: InMemoryKeyValueStore()),
        now: { focusDate(10, 0) },
        startsTimer: false,
        onCompleted: {}
    )
    try expectEqual(model.phase, .idle, "phase")
    try expectEqual(model.selectedMinutes, 25, "minutes")
    try expectEqual(model.remainingSeconds, 1_500, "remaining")
},
TestCase(name: "focus duration selection clamps to the supported range") {
    let model = makeFocusModel()
    model.select(minutes: 2)
    try expectEqual(model.selectedMinutes, 5, "minimum")
    model.select(minutes: 240)
    try expectEqual(model.selectedMinutes, 180, "maximum")
},
TestCase(name: "running focus timer follows its absolute deadline") {
    let model = makeFocusModel()
    model.start(at: focusDate(10, 0))
    model.refresh(at: focusDate(10, 5))
    try expectEqual(model.phase, .running, "phase")
    try expectEqual(model.remainingSeconds, 1_200, "remaining")
},
TestCase(name: "focus timer pauses and resumes from exact remaining time") {
    let model = makeFocusModel()
    model.start(at: focusDate(10, 0))
    model.pause(at: focusDate(10, 5))
    try expectEqual(model.phase, .paused, "paused phase")
    try expectEqual(model.remainingSeconds, 1_200, "paused remaining")
    model.resume(at: focusDate(10, 10))
    model.refresh(at: focusDate(10, 15))
    try expectEqual(model.remainingSeconds, 900, "resumed remaining")
},
TestCase(name: "focus timer completes once and resets cleanly") {
    var completions = 0
    let model = makeFocusModel(onCompleted: { completions += 1 })
    model.start(at: focusDate(10, 0))
    model.refresh(at: focusDate(10, 25))
    model.refresh(at: focusDate(10, 26))
    try expectEqual(model.phase, .completed, "completed phase")
    try expectEqual(completions, 1, "completion callbacks")
    model.reset()
    try expectEqual(model.phase, .idle, "reset phase")
    try expectEqual(model.remainingSeconds, 1_500, "reset remaining")
},
TestCase(name: "running focus timer restores from persisted deadline") {
    let memory = InMemoryKeyValueStore()
    let store = FocusTimerStore(store: memory)
    let first = FocusTimerModel(
        store: store,
        now: { focusDate(10, 0) },
        startsTimer: false,
        onCompleted: {}
    )
    first.start(at: focusDate(10, 0))
    let restored = FocusTimerModel(
        store: store,
        now: { focusDate(10, 10) },
        startsTimer: false,
        onCompleted: {}
    )
    try expectEqual(restored.phase, .running, "restored phase")
    try expectEqual(restored.remainingSeconds, 900, "restored remaining")
}
```

在 `AllTests.swift` 组合末尾加入 `+ focusTimerTests`，在 `scripts/test.sh` 中加入两个新生产文件和 `FocusTimerTests.swift`。

- [ ] **Step 2: 运行测试并确认编译失败**

Run: `bash scripts/test.sh`

Expected: FAIL，原因是 `FocusTimerModel` 和 `FocusTimerStore` 尚未定义。

- [ ] **Step 3: 实现持久化记录**

在 `FocusTimerStore.swift` 定义：

```swift
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
```

- [ ] **Step 4: 实现专注计时模型**

在 `FocusTimerModel.swift` 实现独立 `ObservableObject`，要求：

```swift
@MainActor
final class FocusTimerModel: ObservableObject {
    static let minuteRange = 5...180
    static let minuteStep = 5

    @Published private(set) var selectedMinutes: Int
    @Published private(set) var phase: FocusTimerPhase
    @Published private(set) var remainingSeconds: TimeInterval
    @Published private(set) var endDate: Date?

    var progress: Double {
        let total = Double(selectedMinutes * 60)
        guard total > 0 else { return 0 }
        return min(1, max(0, 1 - remainingSeconds / total))
    }
}
```

模型初始化时读取 `FocusTimerStore`，运行态通过 `endDate.timeIntervalSince(date)` 刷新，完成时清除结束时间、保存状态并只调用一次 `onCompleted`。`startsTimer` 为真时使用 0.25 秒 Combine 定时器调用 `refresh(at:)`。

- [ ] **Step 5: 运行测试并提交**

Run: `bash scripts/test.sh`

Expected: 40 项功能测试全部通过，图标契约通过。

Commit:

```bash
git add Sources/CowHorseClock/Persistence/FocusTimerStore.swift \
  Sources/CowHorseClock/Features/Focus/FocusTimerModel.swift \
  Tests/CowHorseClockTests/FocusTimerTests.swift \
  Tests/CowHorseClockTests/AllTests.swift scripts/test.sh
git commit -m "feat: add persistent focus timer model"
```

---

### Task 2: 添加独立路由与仪表盘入口

**Files:**
- Create: `Tests/CowHorseClockTests/FocusTimerSourceTests.swift`
- Create: `Sources/CowHorseClock/Features/Focus/FocusTimerView.swift`
- Modify: `Tests/CowHorseClockTests/AllTests.swift`
- Modify: `scripts/test.sh`
- Modify: `Sources/CowHorseClock/AppModel.swift`
- Modify: `Sources/CowHorseClock/CowHorseClockApp.swift`
- Modify: `Sources/CowHorseClock/Features/RootPopoverView.swift`
- Modify: `Sources/CowHorseClock/Features/Dashboard/DashboardView.swift`

**Interfaces:**
- Consumes: `FocusTimerModel`
- Produces: `AppRoute.focus`、仪表盘专注入口、专注模型环境注入

- [ ] **Step 1: 写失败的路由源码测试**

创建 `FocusTimerSourceTests.swift`，读取相关源码并断言：

```swift
try expect(appModelSource.contains("case focus"), "app route should include focus")
try expect(
    rootSource.contains("case .focus:") && rootSource.contains("FocusTimerView("),
    "root popover should route to the focus page"
)
try expect(
    dashboardSource.contains("model.route = .focus")
        && dashboardSource.contains("Image(systemName: \"timer\")"),
    "dashboard should expose a focus timer entry"
)
try expect(
    appSource.contains("@StateObject private var focusTimer")
        && appSource.contains(".environmentObject(focusTimer)"),
    "app should own and inject the independent focus timer"
)
```

把新测试文件接入 `scripts/test.sh` 和 `AllTests.swift`。

- [ ] **Step 2: 运行测试并确认失败**

Run: `bash scripts/test.sh`

Expected: FAIL，输出 `app route should include focus`。

- [ ] **Step 3: 添加路由与环境模型**

- 在 `AppRoute` 中添加 `case focus`。
- 在 `CowHorseClockApp` 中添加 `@StateObject private var focusTimer = FocusTimerModel()`，并向 `RootPopoverView` 注入。
- 在 `RootPopoverView` 中处理 `.focus`，创建 `FocusTimerView`，返回操作设置 `model.route = .dashboard`。
- 创建最小可编译的 `FocusTimerView(onBack:)`，使用 `@EnvironmentObject private var focus: FocusTimerModel`，显示 `FOCUS MODE` 标题和调用 `onBack` 的返回按钮。完整倒计时界面在 Task 3 的失败测试后实现。

- [ ] **Step 4: 添加仪表盘入口**

在设置按钮左侧添加薄荷色紧凑按钮：

```swift
Button {
    model.route = .focus
} label: {
    Image(systemName: "timer")
        .frame(width: 30, height: 30)
        .softPunchCard(fill: .punchMint, radius: 12)
}
.buttonStyle(.plain)
.hoverLift(.compact)
.help("专注时间")
```

- [ ] **Step 5: 运行测试并提交**

Run: `bash scripts/test.sh`

Expected: 41 项功能测试全部通过，图标契约通过。

Commit:

```bash
git add Tests/CowHorseClockTests/FocusTimerSourceTests.swift \
  Tests/CowHorseClockTests/AllTests.swift scripts/test.sh \
  Sources/CowHorseClock/AppModel.swift \
  Sources/CowHorseClock/CowHorseClockApp.swift \
  Sources/CowHorseClock/Features/RootPopoverView.swift \
  Sources/CowHorseClock/Features/Dashboard/DashboardView.swift \
  Sources/CowHorseClock/Features/Focus/FocusTimerView.swift
git commit -m "feat: add focus timer navigation"
```

---

### Task 3: 构建独立专注倒计时页面

**Files:**
- Modify: `Sources/CowHorseClock/Features/Focus/FocusTimerView.swift`
- Modify: `Tests/CowHorseClockTests/FocusTimerSourceTests.swift`

**Interfaces:**
- Consumes: `FocusTimerModel` 和 `onBack: () -> Void`
- Produces: 独立的 `FocusTimerView`

- [ ] **Step 1: 写失败的页面源码测试**

追加测试，读取 `FocusTimerView.swift` 并断言：

```swift
try expect(
    [15, 25, 45, 60].allSatisfy {
        source.contains("minutes: \($0)")
    },
    "focus page should expose all approved presets"
)
try expect(source.contains("focus.start()"), "focus page should start")
try expect(source.contains("focus.pause()"), "focus page should pause")
try expect(source.contains("focus.resume()"), "focus page should resume")
try expect(source.contains("focus.reset()"), "focus page should end a session")
try expect(
    !source.contains("snapshot")
        && !source.contains("ledgerStore")
        && !source.contains("EarningsEngine"),
    "focus page must stay independent from earnings and ledger data"
)
```

实现时让模型的 UI 便捷方法 `start()`、`pause()` 和 `resume()` 使用注入的 `now()`，测试仍可调用显式时间版本。

- [ ] **Step 2: 运行测试并确认失败**

Run: `bash scripts/test.sh`

Expected: FAIL，原因是最小 `FocusTimerView` 尚未包含快捷时长和倒计时操作。

- [ ] **Step 3: 实现页面**

扩展 `FocusTimerView(onBack:)`：

- 360pt 宽、约 500pt 高、`FOCUS MODE` 独立标题。
- 返回按钮调用 `onBack`。
- 中央使用两个 `Circle` 与 `.trim(from: 0, to: focus.progress)` 绘制环形进度，内部显示 `MM:SS`。
- 空闲/完成态显示 15、25、45、60 分钟快捷按钮与 ±5 分钟按钮。
- `idle` 显示“开始专注”；`running` 显示“暂停”和“结束本轮”；`paused` 显示“继续”和“结束本轮”；`completed` 显示“再来一轮”和“结束本轮”。
- 所有卡片与按钮使用现有 `softPunchCard` 和 `hoverLift`，但不复用仪表盘半圆表盘或统计卡结构。

- [ ] **Step 4: 最终验证**

Run:

```bash
bash scripts/test.sh
bash scripts/build-app.sh
plutil -lint dist/CowHorseClock.app/Contents/Info.plist
codesign --verify --deep --strict dist/CowHorseClock.app
git diff --check
```

Expected: 42 项功能测试全部通过，图标契约与 Release 构建通过，Info.plist 和签名有效，无空白错误。

- [ ] **Step 5: 提交**

```bash
git add Sources/CowHorseClock/Features/Focus/FocusTimerView.swift \
  Tests/CowHorseClockTests/FocusTimerSourceTests.swift
git commit -m "feat: add independent focus timer page"
```
