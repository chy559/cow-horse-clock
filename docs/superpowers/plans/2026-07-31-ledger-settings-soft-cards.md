# 账本与设置柔和渐变卡片 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将仪表盘的柔和渐变卡片样式延伸到账本和设置页面的普通信息卡与紧凑操作块。

**Architecture:** 复用 `PunchCardTheme.swift` 已提供的 `softPunchCard(fill:radius:)`，只替换 `LedgerView` 和 `SettingsView` 中现有的 `punchCard` 调用。新增独立源码契约测试文件，分别锁定两页的紧凑按钮 `12` 圆角和内容卡 `18` 圆角，同时保证旧卡片调用被完全移除。

**Tech Stack:** Swift 6、SwiftUI、Swift Charts、macOS 14、自定义 Swift 测试运行器。

## Global Constraints

- 账本紧凑按钮使用 `12` continuous 圆角，内容卡使用 `18` continuous 圆角。
- 设置返回按钮使用 `12` continuous 圆角，普通内容卡使用 `18` continuous 圆角。
- 星期圆钮、黑色标题贴纸和黑色保存主按钮保持原样。
- 保留所有现有 `hoverLift`、禁用态和透明度反馈。
- 不修改业务逻辑、页面尺寸、滚动或布局结构。
- 不增加第三方依赖。
- 禁止调用 `pdftotext`。

---

### Task 1: 柔化账本卡片

**Files:**
- Create: `Tests/CowHorseClockTests/SecondaryViewSourceTests.swift`
- Modify: `Tests/CowHorseClockTests/AllTests.swift`
- Modify: `scripts/test.sh`
- Modify: `Sources/CowHorseClock/Features/Ledger/LedgerView.swift`

**Interfaces:**
- Consumes: `View.softPunchCard(fill:radius:)`
- Produces: `secondaryViewSourceTests: [TestCase]` 与全部使用柔和卡片的 `LedgerView`

- [ ] **Step 1: 写账本失败测试并接入测试运行器**

创建 `SecondaryViewSourceTests.swift`：

```swift
import Foundation

let secondaryViewSourceTests: [TestCase] = [
    TestCase(name: "ledger cards use soft gradients and rounder corners") {
        let testsDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let projectDirectory = testsDirectory.deletingLastPathComponent()
        let ledgerURL = projectDirectory.appendingPathComponent(
            "Sources/CowHorseClock/Features/Ledger/LedgerView.swift"
        )
        let source = try String(contentsOf: ledgerURL, encoding: .utf8)

        try expect(
            source.components(
                separatedBy: ".softPunchCard(fill: .punchPaper, radius: 12)"
            ).count - 1 == 2,
            "ledger month controls should use two soft 12-point cards"
        )
        try expect(
            source.contains(".softPunchCard(fill: .punchCoral, radius: 12)"),
            "ledger back button should use a soft 12-point card"
        )
        try expect(
            source.components(
                separatedBy: ".softPunchCard(fill: .punchPaper, radius: 18)"
            ).count - 1 == 3,
            "ledger content should use three soft 18-point cards"
        )
        try expect(
            !source.contains(".punchCard("),
            "ledger should not keep hard-edged punch cards"
        )
    }
]
```

在 `AllTests.swift` 的测试组合末尾加入：

```swift
+ secondaryViewSourceTests
```

在 `scripts/test.sh` 的 Swift 编译输入中加入：

```bash
"$PROJECT_DIR/Tests/CowHorseClockTests/SecondaryViewSourceTests.swift" \
```

- [ ] **Step 2: 运行测试并确认账本测试失败**

Run: `bash scripts/test.sh`

Expected: FAIL，输出 `ledger month controls should use two soft 12-point cards`。

- [ ] **Step 3: 替换账本卡片**

在 `LedgerView.swift` 中进行以下精确替换：

```swift
.punchCard(fill: .punchCoral, radius: 9)
// 改为
.softPunchCard(fill: .punchCoral, radius: 12)

.punchCard(fill: .punchPaper, radius: 8)
// 两处均改为
.softPunchCard(fill: .punchPaper, radius: 12)

.punchCard(fill: .punchPaper)
// 三处均改为
.softPunchCard(fill: .punchPaper, radius: 18)
```

不修改相邻的 `hoverLift`、禁用态或透明度修饰器。

- [ ] **Step 4: 运行测试并确认账本测试通过**

Run: `bash scripts/test.sh`

Expected: 32 项功能测试全部通过，图标契约通过。

- [ ] **Step 5: 提交账本改动**

```bash
git add Tests/CowHorseClockTests/SecondaryViewSourceTests.swift \
  Tests/CowHorseClockTests/AllTests.swift \
  scripts/test.sh \
  Sources/CowHorseClock/Features/Ledger/LedgerView.swift
git commit -m "feat: soften ledger card edges"
```

---

### Task 2: 柔化设置卡片

**Files:**
- Modify: `Tests/CowHorseClockTests/SecondaryViewSourceTests.swift`
- Modify: `Sources/CowHorseClock/Features/Settings/SettingsView.swift`

**Interfaces:**
- Consumes: `View.softPunchCard(fill:radius:)`
- Produces: 普通设置卡全部使用 `18` 圆角、返回按钮使用 `12` 圆角的 `SettingsView`

- [ ] **Step 1: 写设置失败测试**

在 `secondaryViewSourceTests` 中新增：

```swift
TestCase(name: "settings cards use soft gradients and rounder corners") {
    let testsDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let projectDirectory = testsDirectory.deletingLastPathComponent()
    let settingsURL = projectDirectory.appendingPathComponent(
        "Sources/CowHorseClock/Features/Settings/SettingsView.swift"
    )
    let source = try String(contentsOf: settingsURL, encoding: .utf8)

    try expect(
        source.contains(".softPunchCard(fill: .punchCoral, radius: 12)"),
        "settings back button should use a soft 12-point card"
    )
    try expect(
        source.components(
            separatedBy: ".softPunchCard(fill: .punchPaper, radius: 18)"
        ).count - 1 == 2,
        "settings paper cards should use two explicit soft cards"
    )
    try expect(
        source.components(separatedBy: ".softPunchCard(radius: 18)").count - 1 == 2,
        "settings input rows should use two default-fill soft cards"
    )
    try expect(
        !source.contains(".punchCard("),
        "settings should not keep hard-edged punch cards"
    )
}
```

- [ ] **Step 2: 运行测试并确认设置测试失败**

Run: `bash scripts/test.sh`

Expected: FAIL，输出 `settings back button should use a soft 12-point card`。

- [ ] **Step 3: 替换设置卡片**

在 `SettingsView.swift` 中进行以下精确替换：

```swift
.punchCard(fill: .punchCoral, radius: 9)
// 改为
.softPunchCard(fill: .punchCoral, radius: 12)

.punchCard()
// 两处均改为
.softPunchCard(radius: 18)

.punchCard(fill: .punchPaper)
// 三处均改为
.softPunchCard(fill: .punchPaper, radius: 18)
```

不修改星期圆钮、标题贴纸、保存按钮、`hoverLift` 或业务逻辑。

- [ ] **Step 4: 最终验证**

Run:

```bash
bash scripts/test.sh
bash scripts/build-app.sh
plutil -lint dist/CowHorseClock.app/Contents/Info.plist
codesign --verify --deep --strict dist/CowHorseClock.app
git diff --check
```

Expected: 33 项功能测试全部通过，图标契约与 Release 构建通过，Info.plist 和签名有效，无空白错误。

- [ ] **Step 5: 提交设置改动**

```bash
git add Tests/CowHorseClockTests/SecondaryViewSourceTests.swift \
  Sources/CowHorseClock/Features/Settings/SettingsView.swift
git commit -m "feat: soften settings card edges"
```
