# Hover Lift UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为牛马时钟的可点击卡片和重要信息卡增加统一的鼠标悬浮凸起反馈。

**Architecture:** 在共享主题文件中定义可测试的 `HoverLiftStyle` 参数和单一 SwiftUI `ViewModifier`，由各页面显式选择目标组件，避免输入框等排除区域被自动套用。修饰器读取“减少动态效果”环境值，并只通过绘制变换实现凸起，不改变布局尺寸或点击区域。

**Tech Stack:** Swift 6、SwiftUI、macOS 14、现有轻量 Swift 测试运行器

## Global Constraints

- 标准卡片悬浮时上移 5px、缩放至 1.015，并产生 5×5px 黑色硬阴影。
- 紧凑日期格和导航按钮使用 3px 位移与阴影。
- 动画约 0.18 秒，并提升悬浮组件层级。
- “减少动态效果”开启时不执行位移和缩放，只保留轻微阴影。
- 不对薪资输入框、时间选择器、登录启动开关和整页容器应用悬浮凸起。
- 不增加第三方依赖，不改变现有计薪、存储和路由行为。

---

### Task 1: 共享 HoverLift 修饰器

**Files:**
- Modify: `Sources/CowHorseClock/Shared/PunchCardTheme.swift`
- Create: `Tests/CowHorseClockTests/HoverLiftStyleTests.swift`
- Modify: `Tests/CowHorseClockTests/AllTests.swift`
- Modify: `scripts/test.sh`

**Interfaces:**
- Produces: `HoverLiftStyle.standard`
- Produces: `HoverLiftStyle.compact`
- Produces: `View.hoverLift(_:)`

- [ ] **Step 1: 写悬浮参数失败测试**

`HoverLiftStyleTests.swift`：

```swift
import Foundation

let hoverLiftStyleTests: [TestCase] = [
    TestCase(name: "standard hover lift uses approved metrics") {
        try expectEqual(HoverLiftStyle.standard.lift, 5, "lift")
        try expectEqual(HoverLiftStyle.standard.scale, 1.015, "scale")
        try expectEqual(HoverLiftStyle.standard.shadowOffset, 5, "shadow")
    },
    TestCase(name: "compact hover lift uses dense layout metrics") {
        try expectEqual(HoverLiftStyle.compact.lift, 3, "lift")
        try expectEqual(HoverLiftStyle.compact.scale, 1.01, "scale")
        try expectEqual(HoverLiftStyle.compact.shadowOffset, 3, "shadow")
    }
]
```

将 `hoverLiftStyleTests` 加入 `AllTests`，并让 `scripts/test.sh` 编译 `PunchCardTheme.swift` 与新测试。

- [ ] **Step 2: 运行测试确认红灯**

Run: `bash scripts/test.sh`

Expected: FAIL，提示找不到 `HoverLiftStyle`。

- [ ] **Step 3: 实现样式和修饰器**

在 `PunchCardTheme.swift` 中新增：

```swift
enum HoverLiftStyle {
    case standard
    case compact

    var lift: CGFloat { self == .standard ? 5 : 3 }
    var scale: CGFloat { self == .standard ? 1.015 : 1.01 }
    var shadowOffset: CGFloat { self == .standard ? 5 : 3 }
}

private struct HoverLiftModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false
    let style: HoverLiftStyle

    func body(content: Content) -> some View {
        let activeShadow = isHovered
            ? (reduceMotion ? style.shadowOffset * 0.6 : style.shadowOffset)
            : 0
        content
            .offset(y: isHovered && !reduceMotion ? -style.lift : 0)
            .scaleEffect(isHovered && !reduceMotion ? style.scale : 1)
            .shadow(
                color: .punchInk.opacity(isHovered ? 0.92 : 0),
                radius: 0,
                x: activeShadow,
                y: activeShadow
            )
            .zIndex(isHovered ? 10 : 0)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.1)
                    : .spring(response: 0.18, dampingFraction: 0.76),
                value: isHovered
            )
            .onHover { isHovered = $0 }
    }
}

extension View {
    func hoverLift(_ style: HoverLiftStyle = .standard) -> some View {
        modifier(HoverLiftModifier(style: style))
    }
}
```

- [ ] **Step 4: 运行测试与构建**

Run: `bash scripts/test.sh && bash scripts/build-app.sh`

Expected: 全部测试 PASS，Release 应用构建成功。

- [ ] **Step 5: 提交**

```bash
git add Sources/CowHorseClock/Shared/PunchCardTheme.swift Tests scripts/test.sh
git commit -m "feat: add reusable hover lift effect"
```

### Task 2: 将悬浮效果应用到目标组件

**Files:**
- Modify: `Sources/CowHorseClock/Features/Dashboard/DashboardView.swift`
- Modify: `Sources/CowHorseClock/Features/Settings/SettingsView.swift`
- Modify: `Sources/CowHorseClock/Features/Ledger/LedgerView.swift`
- Modify: `Sources/CowHorseClock/Features/Calendar/WorkCalendarView.swift`

**Interfaces:**
- Consumes: `View.hoverLift(_:)`
- Produces: 四个页面一致的卡片悬浮反馈

- [ ] **Step 1: 应用标准悬浮**

在以下卡片的现有 `.punchCard(...)` 后增加 `.hoverLift()`：

```swift
// DashboardView
statCard(...).hoverLift()

// LedgerView
totalCardContent.punchCard(fill: .punchPaper).hoverLift()
chartContent.punchCard(fill: .punchPaper).hoverLift()
recordsContent.punchCard(fill: .punchPaper).hoverLift()

// SettingsView
workCalendarLabel.punchCard(fill: .punchPaper).hoverLift()
saveLabel.hoverLift()
```

薪资、时间范围、登录启动开关和日历整体容器保持不变。

- [ ] **Step 2: 应用紧凑悬浮**

在设置齿轮、返回按钮、月份切换、默认工作日圆形按钮和日期格的 label 上增加：

```swift
.hoverLift(.compact)
```

月份切换按钮先补齐统一的 28×28 punch-card 背景，再应用紧凑悬浮，使硬阴影有明确形状。日历日期格直接在现有圆形 label 后应用紧凑样式。

- [ ] **Step 3: 构建与静态覆盖检查**

Run:

```bash
bash scripts/test.sh
bash scripts/build-app.sh
rg -n "hoverLift" Sources/CowHorseClock/Features
```

Expected: 测试全部 PASS、Release 构建成功，四个功能页面均出现 `hoverLift`，输入框与时间选择器行没有 `hoverLift`。

- [ ] **Step 4: 实机悬浮验证**

启动 `dist/CowHorseClock.app`，在四个页面检查：

- 信息卡进入时上移约 5px并出现硬阴影。
- 日期格和导航按钮上移约 3px。
- 鼠标离开后卡片回落。
- 相邻卡片不遮挡悬浮阴影。
- 点击仍命中原组件。

- [ ] **Step 5: 最终验证并提交**

Run:

```bash
plutil -lint dist/CowHorseClock.app/Contents/Info.plist
codesign --verify --deep --strict dist/CowHorseClock.app
git diff --check
```

Expected: plist 为 `OK`，签名验证退出码为 0，Git diff 无格式错误。

```bash
git add Sources/CowHorseClock/Features
git commit -m "feat: apply hover lift across UI cards"
```
