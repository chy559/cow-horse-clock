# 仪表盘金额右边界修复 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 移除导致主金额末尾数字裁切的负字距，同时保持现有字号、格式、动画和自动缩放行为。

**Architecture:** 在现有 `DashboardSourceTests` 中增加针对主金额代码段的源码契约测试，先证明 `.tracking(-2)` 仍存在并导致测试失败，再只删除该修饰器。业务模型与金额格式化不变。

**Tech Stack:** Swift 6、SwiftUI、macOS 14、自定义 Swift 测试运行器。

## Global Constraints

- 保留 38pt 黑体等宽字体。
- 保留数字过渡、单行显示和 `minimumScaleFactor(0.68)`。
- 不修改金额格式、累计逻辑、面板宽度或其他文字样式。
- 禁止调用 `pdftotext`。

---

### Task 1: 移除主金额负字距

**Files:**
- Modify: `Tests/CowHorseClockTests/DashboardSourceTests.swift`
- Modify: `Sources/CowHorseClock/Features/Dashboard/DashboardView.swift`

**Interfaces:**
- Consumes: `DashboardView.hero` 中的主金额 `Text`
- Produces: 不使用负字距、完整显示末尾字形的主金额

- [ ] **Step 1: 写失败的回归测试**

在 `dashboardSourceTests` 中新增：

```swift
TestCase(name: "hero earnings text does not shrink its glyph boundary") {
    let testsDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let projectDirectory = testsDirectory.deletingLastPathComponent()
    let dashboardURL = projectDirectory
        .appendingPathComponent(
            "Sources/CowHorseClock/Features/Dashboard/DashboardView.swift"
        )
    let source = try String(contentsOf: dashboardURL, encoding: .utf8)
    guard
        let heroStart = source.range(of: "private var hero"),
        let statsStart = source.range(of: "private var stats")
    else {
        throw TestFailure(description: "Dashboard hero not found")
    }
    let hero = source[heroStart.lowerBound..<statsStart.lowerBound]

    try expect(
        !hero.contains(".tracking("),
        "hero earnings text must not use negative tracking"
    )
}
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `bash scripts/test.sh`

Expected: FAIL，输出 `hero earnings text must not use negative tracking`。

- [ ] **Step 3: 实现根因修复**

从主金额文本修饰器中删除：

```swift
.tracking(-2)
```

不修改其他修饰器。

- [ ] **Step 4: 验证**

Run:

```bash
bash scripts/test.sh
bash scripts/build-app.sh
plutil -lint dist/CowHorseClock.app/Contents/Info.plist
codesign --verify --deep --strict dist/CowHorseClock.app
git diff --check
```

Expected: 全部测试通过，Release 构建成功，Info.plist 与签名有效，无空白错误。

- [ ] **Step 5: 提交**

```bash
git add Tests/CowHorseClockTests/DashboardSourceTests.swift \
  Sources/CowHorseClock/Features/Dashboard/DashboardView.swift
git commit -m "fix: prevent hero amount clipping"
```
