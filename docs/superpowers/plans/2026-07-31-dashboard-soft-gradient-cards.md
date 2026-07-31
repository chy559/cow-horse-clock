# 仪表盘柔和渐变卡片 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为仪表盘统计卡和操作按钮增加轻柔渐变、更圆润的四角与柔和边缘，同时保留现有悬浮凸起反馈。

**Architecture:** 在共享主题中增加独立的 `SoftPunchCardModifier` 和 `softPunchCard(fill:radius:)` 接口，但只由 `DashboardView` 使用。通过源码契约测试锁定渐变实现与仪表盘圆角参数，避免意外修改其他页面的 `punchCard` 外观。

**Tech Stack:** Swift 6、SwiftUI、macOS 14、自定义 Swift 测试运行器。

## Global Constraints

- 统计卡使用 `18` continuous 圆角。
- 设置、收工和账本按钮使用 `12` continuous 圆角。
- 使用左上到右下的同色轻渐变、1.5pt 渐变描边和低透明度柔和阴影。
- 保留现有 `hoverLift` 交互。
- 不修改设置、账本、日历、业务数据、金额计算或面板尺寸。
- 不增加第三方依赖。
- 禁止调用 `pdftotext`。

---

### Task 1: 添加仪表盘专用柔和卡片样式

**Files:**
- Modify: `Tests/CowHorseClockTests/DashboardSourceTests.swift`
- Modify: `Sources/CowHorseClock/Shared/PunchCardTheme.swift`
- Modify: `Sources/CowHorseClock/Features/Dashboard/DashboardView.swift`

**Interfaces:**
- Consumes: `Color.punchInk`、现有 `hoverLift(_:)`
- Produces: `View.softPunchCard(fill: Color = .punchPaper, radius: CGFloat = 18) -> some View`

- [ ] **Step 1: 写失败的源码契约测试**

在 `dashboardSourceTests` 中新增一个测试，读取 `PunchCardTheme.swift` 和 `DashboardView.swift`，并断言：

```swift
try expect(
    themeSource.contains("func softPunchCard("),
    "theme should expose the soft punch card modifier"
)
try expect(
    themeSource.contains("LinearGradient("),
    "soft punch card should use a gradient"
)
try expect(
    source.contains(".softPunchCard(fill: fill, radius: 18)"),
    "dashboard stats should use the rounder soft card"
)
try expect(
    source.contains(".softPunchCard(fill: .punchCoral, radius: 12)"),
    "dashboard coral controls should use soft rounded cards"
)
try expect(
    source.contains(".softPunchCard(fill: .punchPaper, radius: 12)"),
    "dashboard ledger control should use a soft rounded card"
)
```

同时更新现有收工按钮测试，使其期待 `.softPunchCard(fill: .punchCoral, radius: 12)`。

- [ ] **Step 2: 运行测试并确认失败**

Run: `bash scripts/test.sh`

Expected: FAIL，输出 `theme should expose the soft punch card modifier` 或新的收工按钮样式断言。

- [ ] **Step 3: 实现柔和卡片修饰器**

在 `PunchCardTheme.swift` 新增：

```swift
private struct SoftPunchCardModifier: ViewModifier {
    var fill: Color = .punchPaper
    var radius: CGFloat = 18

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        content
            .background {
                shape.fill(
                    LinearGradient(
                        colors: [fill, fill.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .clipShape(shape)
            .overlay {
                shape.stroke(
                    LinearGradient(
                        colors: [
                            Color.punchInk.opacity(0.9),
                            Color.punchInk.opacity(0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
            }
            .shadow(color: .punchInk.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}
```

并在 `View` 扩展中新增：

```swift
func softPunchCard(
    fill: Color = .punchPaper,
    radius: CGFloat = 18
) -> some View {
    modifier(SoftPunchCardModifier(fill: fill, radius: radius))
}
```

- [ ] **Step 4: 将仪表盘卡片切换为柔和样式**

在 `DashboardView.swift` 中：

```swift
.softPunchCard(fill: .punchCoral, radius: 12) // 设置按钮
.softPunchCard(fill: fill, radius: 18)        // 统计卡
.softPunchCard(fill: .punchCoral, radius: 12) // 收工按钮
.softPunchCard(fill: .punchPaper, radius: 12) // 账本按钮
```

删除设置按钮原有的手写背景、裁切和描边，保留尺寸、按钮行为和所有 `hoverLift` 修饰器。

- [ ] **Step 5: 验证**

Run:

```bash
bash scripts/test.sh
bash scripts/build-app.sh
plutil -lint dist/CowHorseClock.app/Contents/Info.plist
codesign --verify --deep --strict dist/CowHorseClock.app
git diff --check
```

Expected: 全部测试通过，Release 构建成功，Info.plist 与签名有效，无空白错误。

- [ ] **Step 6: 提交**

```bash
git add Tests/CowHorseClockTests/DashboardSourceTests.swift \
  Sources/CowHorseClock/Shared/PunchCardTheme.swift \
  Sources/CowHorseClock/Features/Dashboard/DashboardView.swift
git commit -m "feat: soften dashboard card edges"
```
