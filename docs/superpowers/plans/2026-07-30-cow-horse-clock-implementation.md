# 牛马时钟 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个可直接运行的 macOS 14+ 原生菜单栏应用，按用户配置的日薪和双工作时段实时展示今日收入，并提供历史账本、工作日历和本地设置。

**Architecture:** 使用 Swift Package Manager 管理一个 SwiftUI 可执行程序，并通过脚本组装为标准 `.app` 包；不依赖完整 Xcode 工程。纯函数 `EarningsEngine` 负责时间与金额推导，SwiftData 负责日历例外和每日结算记录，`UserDefaults` 负责当前工作设置，`AppModel` 统一协调计时、对账与页面状态。

**Tech Stack:** Swift 6、SwiftUI、SwiftData、Charts、ServiceManagement、Swift Package Manager、XCTest、macOS 14 SDK API

**Implementation environment note:** 本机没有完整 Xcode，Command Line Tools 也不包含 SwiftDataMacros 和 XCTest。实施时以 Codable JSON 替代 SwiftData，并使用同工具链直接编译的轻量测试运行器替代 XCTest；业务范围、存储语义和测试覆盖保持不变。

## Global Constraints

- 最低系统版本必须是 macOS 14 Sonoma。
- 应用必须是菜单栏应用，点击外部时弹窗自动收起，不提供常驻桌面窗口。
- 第一版固定人民币，金额内部使用“分”和 `Decimal` 计算，不使用二进制浮点保存货币。
- 上午与下午是两个独立计薪时段，午休、下班后和休息日不计薪。
- 手动休息日优先于默认工作日，手动加班日可覆盖默认休息日。
- 修改配置不得改写已经结算的历史日期。
- 所有业务数据只保存在本机，不增加第三方依赖、网络请求、云同步、通知、多币种或联网节假日。
- UI 使用奶油黄、黑色粗描边和橙红强调色的 punch-card 视觉。

---

## File Structure

```text
Package.swift                                      SwiftPM 产品、平台和测试目标
Sources/CowHorseClock/CowHorseClockApp.swift       菜单栏入口与 SwiftData 容器
Sources/CowHorseClock/AppModel.swift               全局页面状态、计时和对账协调
Sources/CowHorseClock/Domain/WorkSettings.swift    设置、时段、工作日与验证
Sources/CowHorseClock/Domain/EarningsEngine.swift  纯计薪计算
Sources/CowHorseClock/Domain/EarningsSnapshot.swift 计算结果和计薪状态
Sources/CowHorseClock/Persistence/Models.swift     SwiftData 记录
Sources/CowHorseClock/Persistence/SettingsStore.swift UserDefaults 设置存储
Sources/CowHorseClock/Persistence/LedgerStore.swift 结算、聚合与日历例外
Sources/CowHorseClock/Services/LaunchAtLoginService.swift 登录启动
Sources/CowHorseClock/Shared/MoneyFormatter.swift  人民币与时间格式化
Sources/CowHorseClock/Shared/PunchCardTheme.swift  颜色、描边、卡片修饰器
Sources/CowHorseClock/Features/RootPopoverView.swift 首次设置和页面路由
Sources/CowHorseClock/Features/Dashboard/DashboardView.swift 主仪表盘
Sources/CowHorseClock/Features/Dashboard/PunchCardGauge.swift 仪表盘绘制
Sources/CowHorseClock/Features/Ledger/LedgerView.swift 月度账本和历史累计
Sources/CowHorseClock/Features/Settings/SettingsView.swift 薪资、时段与启动设置
Sources/CowHorseClock/Features/Calendar/WorkCalendarView.swift 休息/加班标记
Tests/CowHorseClockTests/WorkSettingsTests.swift    设置验证测试
Tests/CowHorseClockTests/EarningsEngineTests.swift 计薪边界测试
Tests/CowHorseClockTests/LedgerStoreTests.swift     SwiftData 对账测试
Tests/CowHorseClockTests/AppModelTests.swift        固定时钟与设置保存测试
Tests/CowHorseClockTests/MoneyFormatterTests.swift  金额与倒计时格式测试
scripts/build-app.sh                               Release 构建和 .app 组装
```

### Task 1: 可构建的菜单栏应用骨架

**Files:**
- Create: `Package.swift`
- Create: `Sources/CowHorseClock/CowHorseClockApp.swift`
- Create: `Sources/CowHorseClock/Features/RootPopoverView.swift`
- Create: `scripts/build-app.sh`

**Interfaces:**
- Produces: SwiftPM executable product `CowHorseClock`
- Produces: `dist/CowHorseClock.app`
- Produces: `RootPopoverView: View`

- [ ] **Step 1: 创建最小 SwiftPM 包并写一个失败的产品检查**

在 `Package.swift` 声明 macOS 14 executable target 和 test target：

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CowHorseClock",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "CowHorseClock", targets: ["CowHorseClock"])],
    targets: [
        .executableTarget(name: "CowHorseClock"),
        .testTarget(name: "CowHorseClockTests", dependencies: ["CowHorseClock"])
    ]
)
```

Run: `swift build`

Expected: FAIL，因为应用入口尚不存在。

- [ ] **Step 2: 实现最小菜单栏入口**

`CowHorseClockApp.swift`：

```swift
import SwiftUI

@main
struct CowHorseClockApp: App {
    var body: some Scene {
        MenuBarExtra("牛马时钟", systemImage: "gauge.with.dots.needle.bottom.50percent") {
            RootPopoverView()
        }
        .menuBarExtraStyle(.window)
    }
}
```

`RootPopoverView.swift`：

```swift
import SwiftUI

struct RootPopoverView: View {
    var body: some View {
        Text("牛马时钟")
            .frame(width: 360, height: 480)
    }
}
```

- [ ] **Step 3: 创建标准 app bundle 构建脚本**

`scripts/build-app.sh` 必须执行：

```bash
#!/usr/bin/env bash
set -euo pipefail
swift build -c release
APP_DIR="dist/CowHorseClock.app"
BIN_DIR="$APP_DIR/Contents/MacOS"
mkdir -p "$BIN_DIR"
cp ".build/release/CowHorseClock" "$BIN_DIR/CowHorseClock"
plutil -create xml1 "$APP_DIR/Contents/Info.plist"
plutil -insert CFBundleName -string "牛马时钟" "$APP_DIR/Contents/Info.plist"
plutil -insert CFBundleDisplayName -string "牛马时钟" "$APP_DIR/Contents/Info.plist"
plutil -insert CFBundleIdentifier -string "com.local.CowHorseClock" "$APP_DIR/Contents/Info.plist"
plutil -insert CFBundleExecutable -string "CowHorseClock" "$APP_DIR/Contents/Info.plist"
plutil -insert CFBundlePackageType -string "APPL" "$APP_DIR/Contents/Info.plist"
plutil -insert CFBundleShortVersionString -string "1.0.0" "$APP_DIR/Contents/Info.plist"
plutil -insert CFBundleVersion -string "1" "$APP_DIR/Contents/Info.plist"
plutil -insert LSMinimumSystemVersion -string "14.0" "$APP_DIR/Contents/Info.plist"
plutil -insert LSUIElement -bool true "$APP_DIR/Contents/Info.plist"
codesign --force --deep --sign - "$APP_DIR"
echo "$APP_DIR"
```

- [ ] **Step 4: 验证骨架**

Run: `swift build && bash scripts/build-app.sh`

Expected: `Build complete!`，`codesign` 成功，输出 `dist/CowHorseClock.app`。

- [ ] **Step 5: 提交**

```bash
git add Package.swift Sources scripts
git commit -m "build: scaffold native menu bar app"
```

### Task 2: 工作设置与验证

**Files:**
- Create: `Sources/CowHorseClock/Domain/WorkSettings.swift`
- Create: `Tests/CowHorseClockTests/WorkSettingsTests.swift`

**Interfaces:**
- Produces: `TimeRange(startMinute:endMinute:)`
- Produces: `WorkSettings.default`, `WorkSettings.validationErrors`
- Produces: `CalendarOverrideKind`

- [ ] **Step 1: 写失败测试**

测试必须覆盖默认 `09:00–12:00`、`13:30–18:00`、周一至周五、日薪 40000 分，以及交叉时段和零总时长验证：

```swift
import XCTest
@testable import CowHorseClock

final class WorkSettingsTests: XCTestCase {
    func testDefaultSettingsAreValid() {
        let value = WorkSettings.default
        XCTAssertEqual(value.dailySalaryCents, 40_000)
        XCTAssertEqual(value.morning, TimeRange(startMinute: 540, endMinute: 720))
        XCTAssertEqual(value.afternoon, TimeRange(startMinute: 810, endMinute: 1080))
        XCTAssertTrue(value.validationErrors.isEmpty)
    }

    func testOverlappingRangesAreRejected() {
        var value = WorkSettings.default
        value.afternoon = TimeRange(startMinute: 700, endMinute: 1080)
        XCTAssertEqual(value.validationErrors, [.rangesOverlap])
    }
}
```

Run: `swift test --filter WorkSettingsTests`

Expected: FAIL，`WorkSettings` 未定义。

- [ ] **Step 2: 实现值类型**

`WorkSettings.swift` 必须包含：

```swift
import Foundation

struct TimeRange: Codable, Equatable, Sendable {
    var startMinute: Int
    var endMinute: Int
    var durationSeconds: Int { max(0, endMinute - startMinute) * 60 }
}

enum SettingsValidationError: Equatable {
    case negativeSalary, invalidMorningRange, invalidAfternoonRange
    case rangesOverlap, noWorkday
}

enum CalendarOverrideKind: String, Codable, CaseIterable, Sendable {
    case rest, work
}

struct WorkSettings: Codable, Equatable, Sendable {
    var dailySalaryCents: Int64
    var morning: TimeRange
    var afternoon: TimeRange
    var defaultWeekdays: Set<Int>
    var launchAtLogin: Bool
    var trackingStartDate: Date?
    var lastReconciledDate: Date?

    static let `default` = WorkSettings(
        dailySalaryCents: 40_000,
        morning: .init(startMinute: 540, endMinute: 720),
        afternoon: .init(startMinute: 810, endMinute: 1080),
        defaultWeekdays: [2, 3, 4, 5, 6],
        launchAtLogin: false,
        trackingStartDate: nil,
        lastReconciledDate: nil
    )

    var validationErrors: [SettingsValidationError] {
        var errors: [SettingsValidationError] = []
        if dailySalaryCents < 0 { errors.append(.negativeSalary) }
        if morning.durationSeconds == 0 { errors.append(.invalidMorningRange) }
        if afternoon.durationSeconds == 0 { errors.append(.invalidAfternoonRange) }
        if morning.endMinute > afternoon.startMinute { errors.append(.rangesOverlap) }
        if defaultWeekdays.isEmpty { errors.append(.noWorkday) }
        return errors
    }
}
```

- [ ] **Step 3: 补齐边界测试并通过**

增加负日薪、倒置时段、空工作日集合和合法相邻时段测试。

Run: `swift test --filter WorkSettingsTests`

Expected: 所有 `WorkSettingsTests` PASS。

- [ ] **Step 4: 提交**

```bash
git add Sources/CowHorseClock/Domain/WorkSettings.swift Tests/CowHorseClockTests/WorkSettingsTests.swift
git commit -m "feat: define validated work settings"
```

### Task 3: 纯计薪引擎

**Files:**
- Create: `Sources/CowHorseClock/Domain/EarningsSnapshot.swift`
- Create: `Sources/CowHorseClock/Domain/EarningsEngine.swift`
- Create: `Tests/CowHorseClockTests/EarningsEngineTests.swift`

**Interfaces:**
- Consumes: `WorkSettings`, `TimeRange`
- Produces: `EarningsState`
- Produces: `EarningsSnapshot`
- Produces: `EarningsEngine.snapshot(at:settings:isWorkday:calendar:)`

- [ ] **Step 1: 写状态边界失败测试**

使用固定时区和 `Calendar(identifier: .gregorian)`，覆盖：

```swift
func testMorningHalfwayEarnsProportionalAmount() {
    let now = makeDate("2026-07-30 10:30")
    let result = EarningsEngine.snapshot(
        at: now, settings: .default, isWorkday: true, calendar: calendar
    )
    XCTAssertEqual(result.state, .workingMorning)
    XCTAssertEqual(result.earnedCents, Decimal(8_000))
    XCTAssertEqual(result.progress, 0.2, accuracy: 0.0001)
}

func testLunchPausesAtMorningAmount() {
    let result = snapshot("2026-07-30 12:45")
    XCTAssertEqual(result.state, .lunch)
    XCTAssertEqual(result.earnedCents, Decimal(16_000))
}

func testRestDayEarnsZero() {
    let result = EarningsEngine.snapshot(
        at: makeDate("2026-07-30 15:00"),
        settings: .default,
        isWorkday: false,
        calendar: calendar
    )
    XCTAssertEqual(result.state, .restDay)
    XCTAssertEqual(result.earnedCents, .zero)
}
```

Run: `swift test --filter EarningsEngineTests`

Expected: FAIL，`EarningsEngine` 未定义。

- [ ] **Step 2: 实现结果和值状态**

```swift
enum EarningsState: Equatable, Sendable {
    case beforeWork, workingMorning, lunch, workingAfternoon, finished, restDay
}

struct EarningsSnapshot: Equatable, Sendable {
    let earnedCents: Decimal
    let rateCentsPerSecond: Decimal
    let progress: Double
    let state: EarningsState
    let secondsUntilNextTransition: Int?
}
```

`EarningsEngine.snapshot` 将当天午夜作为基准，把当前时间转换成“当天经过秒数”，计算两个时段内已经经过的有效秒数，最后执行：

```swift
let total = settings.morning.durationSeconds + settings.afternoon.durationSeconds
let rate = Decimal(settings.dailySalaryCents) / Decimal(total)
let earned = min(Decimal(settings.dailySalaryCents), max(.zero, rate * Decimal(elapsed)))
```

下一节点分别是上午上班、午休开始、下午上班和下班；休息日没有下一节点。

- [ ] **Step 3: 补齐所有状态测试**

覆盖上班前、上午开始精确边界、午休、下午开始、下班精确边界、下班后、休息日、零日薪和系统时间早于当天午夜时的下限保护。

Run: `swift test --filter EarningsEngineTests`

Expected: 所有 `EarningsEngineTests` PASS。

- [ ] **Step 4: 提交**

```bash
git add Sources/CowHorseClock/Domain Tests/CowHorseClockTests/EarningsEngineTests.swift
git commit -m "feat: calculate real-time earnings"
```

### Task 4: 本地存储、日历例外与账本对账

**Files:**
- Create: `Sources/CowHorseClock/Persistence/Models.swift`
- Create: `Sources/CowHorseClock/Persistence/SettingsStore.swift`
- Create: `Sources/CowHorseClock/Persistence/LedgerStore.swift`
- Create: `Tests/CowHorseClockTests/LedgerStoreTests.swift`

**Interfaces:**
- Produces: SwiftData models `CalendarOverride` and `DailyEarningRecord`
- Produces: `SettingsStore.load()`, `SettingsStore.save(_:)`
- Produces: `LedgerStore.isWorkday(_:settings:)`
- Produces: `LedgerStore.reconcile(settings:through:)`
- Produces: `LedgerStore.monthSummary(containing:)`

- [ ] **Step 1: 写内存 SwiftData 失败测试**

测试使用：

```swift
let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try ModelContainer(
    for: CalendarOverride.self, DailyEarningRecord.self,
    configurations: configuration
)
let store = LedgerStore(context: ModelContext(container), calendar: calendar)
```

断言周六默认休息、周六手动 `.work` 后计薪、周四手动 `.rest` 后休息；对账同一日期两次只产生一条记录；关闭三天后对账会补齐期间工作日。

Run: `swift test --filter LedgerStoreTests`

Expected: FAIL，存储类型未定义。

- [ ] **Step 2: 实现 SwiftData 模型**

```swift
import Foundation
import SwiftData

@Model
final class CalendarOverride {
    @Attribute(.unique) var dateKey: String
    var kindRawValue: String

    init(dateKey: String, kind: CalendarOverrideKind) {
        self.dateKey = dateKey
        self.kindRawValue = kind.rawValue
    }
}

@Model
final class DailyEarningRecord {
    @Attribute(.unique) var dateKey: String
    var salaryCents: Int64
    var morningStart: Int
    var morningEnd: Int
    var afternoonStart: Int
    var afternoonEnd: Int
    var earnedCents: Int64
    var settledAt: Date
}
```

- [ ] **Step 3: 实现设置存储**

`SettingsStore` 接收可注入的 `UserDefaults`，使用单一键 `cowHorseClock.workSettings.v1` 保存 `Codable` JSON。解码失败返回 `.default`，保存失败抛出明确的 `SettingsStoreError.encodingFailed`。

- [ ] **Step 4: 实现账本规则与对账**

`LedgerStore` 使用本地日历生成稳定 `yyyy-MM-dd` 键。`isWorkday` 先查询 `CalendarOverride`，再查询 `settings.defaultWeekdays`。`reconcile` 只结算今天之前、追踪开始日之后且不存在记录的有效工作日，每天结算为当时配置的完整 `dailySalaryCents`。

月度摘要类型：

```swift
struct MonthSummary {
    let monthStart: Date
    let settledCents: Int64
    let records: [DailyEarningRecord]
}
```

- [ ] **Step 5: 运行测试**

Run: `swift test --filter LedgerStoreTests`

Expected: 日历覆盖、唯一结算、遗漏日期补齐、月份聚合测试全部 PASS。

- [ ] **Step 6: 提交**

```bash
git add Sources/CowHorseClock/Persistence Tests/CowHorseClockTests/LedgerStoreTests.swift
git commit -m "feat: persist schedules and earning ledger"
```

### Task 5: AppModel、实时刷新与登录启动

**Files:**
- Create: `Sources/CowHorseClock/AppModel.swift`
- Create: `Sources/CowHorseClock/Services/LaunchAtLoginService.swift`
- Create: `Tests/CowHorseClockTests/AppModelTests.swift`
- Modify: `Sources/CowHorseClock/CowHorseClockApp.swift`
- Modify: `Sources/CowHorseClock/Features/RootPopoverView.swift`

**Interfaces:**
- Consumes: `SettingsStore`, `LedgerStore`, `EarningsEngine`
- Produces: `AppModel.snapshot`, `AppModel.settings`, `AppModel.route`
- Produces: `AppModel.saveSettings(_:)`, `AppModel.refresh(at:)`
- Produces: `LaunchAtLoginService.setEnabled(_:)`

- [ ] **Step 1: 为可注入时钟写 AppModel 测试**

在测试中注入固定 `now` 闭包，断言初始化会读取设置、刷新快照、首次配置时设置 `trackingStartDate`，保存无效设置会抛出 `AppModelError.invalidSettings`。

Run: `swift test --filter AppModelTests`

Expected: FAIL，`AppModel` 未定义。

- [ ] **Step 2: 实现 AppModel**

`AppModel` 标记 `@MainActor final class AppModel: ObservableObject`，发布：

```swift
@Published private(set) var snapshot: EarningsSnapshot
@Published var settings: WorkSettings
@Published var route: AppRoute = .dashboard
@Published private(set) var ledgerRevision = UUID()
```

刷新使用 `Timer.publish(every: 0.25, on: .main, in: .common)`；每次 tick 根据墙上时间重算，不累加旧值。应用激活、系统唤醒和日期变化通知触发立即刷新与对账。

- [ ] **Step 3: 实现登录启动服务**

`LaunchAtLoginService` 使用 `SMAppService.mainApp.register()` 和 `unregister()`；注册失败回滚 UI 开关并把本地化错误交给设置页面展示。

- [ ] **Step 4: 注入真实容器**

`CowHorseClockApp` 创建 `ModelContainer(for: CalendarOverride.self, DailyEarningRecord.self)`，构建一个共享 `AppModel` 并通过 `.environmentObject(appModel)` 注入菜单栏内容。

- [ ] **Step 5: 运行全部测试**

Run: `swift test`

Expected: 所有 domain、persistence 和 AppModel 测试 PASS。

- [ ] **Step 6: 提交**

```bash
git add Sources Tests
git commit -m "feat: coordinate live earnings state"
```

### Task 6: Punch-card 主仪表盘

**Files:**
- Create: `Sources/CowHorseClock/Shared/MoneyFormatter.swift`
- Create: `Sources/CowHorseClock/Shared/PunchCardTheme.swift`
- Create: `Sources/CowHorseClock/Features/Dashboard/PunchCardGauge.swift`
- Create: `Sources/CowHorseClock/Features/Dashboard/DashboardView.swift`
- Create: `Tests/CowHorseClockTests/MoneyFormatterTests.swift`
- Modify: `Sources/CowHorseClock/Features/RootPopoverView.swift`

**Interfaces:**
- Consumes: `AppModel.snapshot`
- Produces: `MoneyFormatter.yuan(cents:)`
- Produces: `PunchCardGauge(progress:)`
- Produces: `DashboardView`

- [ ] **Step 1: 写格式化失败测试**

```swift
func testMoneyFormatterUsesTwoFractionDigits() {
    XCTAssertEqual(MoneyFormatter.yuan(cents: Decimal(28_642)), "¥286.42")
}
```

Run: `swift test --filter MoneyFormatterTests`

Expected: FAIL，格式化器未定义。

- [ ] **Step 2: 实现金额与倒计时格式化**

`MoneyFormatter` 使用固定 `zh_CN` locale、人民币符号和两位小数；倒计时格式固定为 `HH:mm:ss`，超过 99 小时仍显示完整小时数。

- [ ] **Step 3: 实现主题与仪表盘**

定义：

```swift
extension Color {
    static let punchCream = Color(red: 1.0, green: 0.965, blue: 0.74)
    static let punchInk = Color(red: 0.09, green: 0.09, blue: 0.09)
    static let punchCoral = Color(red: 1.0, green: 0.45, blue: 0.34)
}
```

`PunchCardGauge` 使用 `Canvas` 绘制半圆底轨、进度弧、刻度和旋转指针；`progress` 强制限定在 `0...1`，动画使用 `.spring(response: 0.45, dampingFraction: 0.78)`。

- [ ] **Step 4: 实现 DashboardView**

固定弹窗宽度 360，高度约 500。页面顺序必须是品牌与设置按钮、今日金额、每秒收入、仪表盘、状态倒计时、今日进度与本月累计卡片、账本入口。状态文案严格映射：

```swift
switch snapshot.state {
case .beforeWork: "工位引擎尚未点火"
case .workingMorning, .workingAfternoon: "每秒回血 \(rate)"
case .lunch: "暂停燃烧生命"
case .finished: "今日自由已到账"
case .restDay: "今天不当牛马"
}
```

- [ ] **Step 5: 构建验证**

Run: `swift test && swift build`

Expected: 全部测试 PASS，SwiftUI target 编译成功且无 error。

- [ ] **Step 6: 提交**

```bash
git add Sources Tests
git commit -m "feat: build punch-card dashboard"
```

### Task 7: 账本、设置、日历和首次启动

**Files:**
- Create: `Sources/CowHorseClock/Features/Ledger/LedgerView.swift`
- Create: `Sources/CowHorseClock/Features/Settings/SettingsView.swift`
- Create: `Sources/CowHorseClock/Features/Calendar/WorkCalendarView.swift`
- Modify: `Sources/CowHorseClock/Features/RootPopoverView.swift`
- Modify: `Sources/CowHorseClock/AppModel.swift`

**Interfaces:**
- Consumes: `AppModel`, `LedgerStore`, `WorkSettings.validationErrors`
- Produces: 完整 `.dashboard`、`.ledger`、`.settings`、`.calendar` 路由

- [ ] **Step 1: 实现首次设置和路由**

`RootPopoverView` 在 `trackingStartDate == nil` 时显示设置页并隐藏返回按钮；完成有效保存后设置追踪起始日为当天并切换 `.dashboard`。其他页面使用显式返回按钮，不依赖导航栏占用额外空间。

- [ ] **Step 2: 实现设置页**

日薪输入以元显示，保存时严格转换为分。两个时段使用 `DatePicker` 的小时分钟组件；工作日使用一到日七个可切换按钮。校验错误在对应字段下用中文显示，存在错误时禁用保存。

- [ ] **Step 3: 实现工作日历**

展示当前月 7 列日历，点击日期循环：

```text
未标记 → 休息日 → 加班日 → 未标记
```

休息日使用灰色删除线，加班日使用橙红圆形标记；默认工作日只显示轻微底色。切换月份不会改变已保存标记。

- [ ] **Step 4: 实现账本**

显示本月累计、历史总计、七列日收入柱状图和每日记录列表。当天金额从 `AppModel.snapshot` 实时读取，已结算日期从 `LedgerStore` 读取；月份切换仅允许到追踪起始月，不展示安装之前的伪记录。

- [ ] **Step 5: 集成检查**

Run: `swift test && swift build`

Expected: 全部测试 PASS，四个页面路由和首次设置分支编译成功。

- [ ] **Step 6: 提交**

```bash
git add Sources
git commit -m "feat: add ledger settings and work calendar"
```

### Task 8: 成品打包与真实运行验证

**Files:**
- Modify: `scripts/build-app.sh`
- Create: `README.md`

**Interfaces:**
- Produces: `dist/CowHorseClock.app`
- Produces: 用户可复制到 `/Applications` 的 ad-hoc signed app

- [ ] **Step 1: 完善构建脚本的确定性**

脚本开头解析仓库绝对路径并 `cd` 到仓库，构建前删除明确的 `dist/CowHorseClock.app` 旧包，再创建目标目录；不得删除其他 `dist` 内容。

- [ ] **Step 2: 编写 README**

README 包含产品截图位置、功能清单、macOS 14+ 要求、构建命令：

```bash
swift test
bash scripts/build-app.sh
open dist/CowHorseClock.app
```

并说明首次启动需要填写日薪和工作时间，数据仅保存在本机。

- [ ] **Step 3: 执行最终自动验证**

Run:

```bash
swift test
bash scripts/build-app.sh
plutil -lint dist/CowHorseClock.app/Contents/Info.plist
codesign --verify --deep --strict dist/CowHorseClock.app
```

Expected: 测试全 PASS，plist 为 `OK`，签名验证退出码为 0。

- [ ] **Step 4: 实际启动应用**

Run: `open dist/CowHorseClock.app`

Expected: 菜单栏出现仪表图标；点击显示首次设置；保存后显示 punch-card 仪表盘；点击外部弹窗收起；设置、账本和工作日历均能打开并返回。

- [ ] **Step 5: 检查运行日志**

Run: `log show --last 5m --predicate 'process == "CowHorseClock"' --style compact`

Expected: 没有 crash、SwiftData migration failure 或反复注册登录项错误。

- [ ] **Step 6: 提交**

```bash
git add README.md scripts/build-app.sh
git commit -m "docs: package and document Cow Horse Clock"
```

- [ ] **Step 7: 最终状态检查**

Run: `git status --short && git log --oneline --decorate -8`

Expected: 工作区干净，历史包含设计、计划和各功能提交。
