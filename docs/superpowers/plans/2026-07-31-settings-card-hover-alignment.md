# 设置卡片悬浮反馈对齐 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为设置页三个遗漏的普通卡片容器补齐与仪表盘统计卡一致的鼠标悬浮凸起反馈。

**Architecture:** 保留共享 `softPunchCard` 和 `HoverLiftModifier` 不变，只在 `SettingsView` 的薪资卡、`timeRangeRow` 与登录启动卡后显式应用 `hoverLift()`。源码契约测试按代码区段验证三处交互，避免仅用总次数产生误判。

**Tech Stack:** Swift 6、SwiftUI、macOS 14、自定义 Swift 测试运行器。

## Global Constraints

- 不改变 18 圆角、柔和对角渐变、渐变描边和轻微阴影。
- 只让卡片容器上浮，不让字段标题一起移动。
- 不修改账本、仪表盘、星期圆钮、保存按钮或业务逻辑。
- 禁止调用 `pdftotext`。

---

### Task 1: 补齐设置普通卡片悬浮反馈

**Files:**
- Modify: `Tests/CowHorseClockTests/SecondaryViewSourceTests.swift`
- Modify: `Sources/CowHorseClock/Features/Settings/SettingsView.swift`

**Interfaces:**
- Consumes: `View.hoverLift(_ style: HoverLiftStyle = .standard)`
- Produces: 薪资、时间段和登录启动卡均支持标准悬浮凸起的 `SettingsView`

- [ ] **Step 1: 写失败的源码契约测试**

在 `secondaryViewSourceTests` 中新增：

```swift
TestCase(name: "settings soft cards keep dashboard hover feedback") {
    let testsDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let projectDirectory = testsDirectory.deletingLastPathComponent()
    let settingsURL = projectDirectory.appendingPathComponent(
        "Sources/CowHorseClock/Features/Settings/SettingsView.swift"
    )
    let source = try String(contentsOf: settingsURL, encoding: .utf8)

    guard
        let salaryStart = source.range(of: "fieldGroup(\"每日薪资\")"),
        let morningStart = source.range(of: "fieldGroup(\"上午计薪\")"),
        let toggleStart = source.range(of: "Toggle(isOn: $draft.launchAtLogin)"),
        let calendarStart = source.range(of: "if !isOnboarding {", range: toggleStart.upperBound..<source.endIndex),
        let timeRowStart = source.range(of: "private func timeRangeRow"),
        let timeBindingStart = source.range(of: "private func timeBinding")
    else {
        throw TestFailure(description: "Settings card sections not found")
    }

    let salary = source[salaryStart.lowerBound..<morningStart.lowerBound]
    let toggle = source[toggleStart.lowerBound..<calendarStart.lowerBound]
    let timeRow = source[timeRowStart.lowerBound..<timeBindingStart.lowerBound]

    try expect(salary.contains(".hoverLift()"), "salary card should lift on hover")
    try expect(toggle.contains(".hoverLift()"), "launch card should lift on hover")
    try expect(timeRow.contains(".hoverLift()"), "time cards should lift on hover")
}
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `bash scripts/test.sh`

Expected: FAIL，输出 `salary card should lift on hover`。

- [ ] **Step 3: 实现最小修复**

在 `SettingsView.swift` 三处现有 `softPunchCard` 后追加：

```swift
.hoverLift()
```

目标分别是每日薪资 `HStack`、登录启动 `Toggle` 和 `timeRangeRow` 的 `HStack`。

- [ ] **Step 4: 验证**

Run:

```bash
bash scripts/test.sh
bash scripts/build-app.sh
plutil -lint dist/CowHorseClock.app/Contents/Info.plist
codesign --verify --deep --strict dist/CowHorseClock.app
git diff --check
```

Expected: 34 项功能测试全部通过，图标契约和 Release 构建通过，Info.plist 与签名有效，无空白错误。

- [ ] **Step 5: 提交**

```bash
git add Tests/CowHorseClockTests/SecondaryViewSourceTests.swift \
  Sources/CowHorseClock/Features/Settings/SettingsView.swift
git commit -m "fix: align settings card hover feedback"
```
