# “收工”按钮视觉优化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将仪表盘左下角的“收工”按钮改造成清晰、好看且符合打卡纸风格的珊瑚色打卡章。

**Architecture:** 只修改 `DashboardView` 中现有退出按钮的标签样式，不改变退出动作。用源码契约测试锁定按钮的卡片样式、紧凑悬停效果与帮助提示，避免后续退化成普通文字按钮。

**Tech Stack:** Swift 5.10、SwiftUI、macOS 14、自定义 Swift 测试运行器。

## Global Constraints

- 保留 `NSApplication.shared.terminate(nil)` 退出行为。
- 复用现有 `punchCard` 和 `hoverLift(.compact)`，不新增依赖。
- 不修改仪表盘其他控件。

---

### Task 1: 刷新“收工”按钮

**Files:**
- Modify: `Sources/CowHorseClock/Features/Dashboard/DashboardView.swift`
- Create: `Tests/CowHorseClockTests/DashboardSourceTests.swift`
- Modify: `Tests/CowHorseClockTests/AllTests.swift`
- Modify: `scripts/test.sh`

**Interfaces:**
- Consumes: `View.punchCard(fill:radius:)`、`View.hoverLift(_:)`
- Produces: 珊瑚色打卡章样式的退出按钮

- [ ] **Step 1: 写失败的源码契约测试**

新增 `dashboardSourceTests`，读取 `DashboardView.swift` 中 `private var footer` 到第一个 `Spacer()` 之间的退出按钮代码，断言包含：

```swift
.punchCard(fill: .punchCoral, radius: 9)
.hoverLift(.compact)
.help("退出 CowHorseClock")
```

把测试加入 `AllTests.swift` 和 `scripts/test.sh`。

- [ ] **Step 2: 运行测试并确认失败**

Run: `bash scripts/test.sh`

Expected: FAIL，指出退出按钮缺少珊瑚色 `punchCard` 样式。

- [ ] **Step 3: 实现最小视觉改动**

将退出按钮标签改为：

```swift
Label("收工", systemImage: "power")
    .font(.system(size: 11, weight: .black, design: .rounded))
    .padding(.horizontal, 10)
    .padding(.vertical, 7)
    .punchCard(fill: .punchCoral, radius: 9)
    .rotationEffect(.degrees(-0.7))
```

在 `.buttonStyle(.plain)` 后加入：

```swift
.hoverLift(.compact)
.help("退出 CowHorseClock")
```

- [ ] **Step 4: 验证**

Run:

```bash
bash scripts/test.sh
bash scripts/build-app.sh
plutil -lint dist/CowHorseClock.app/Contents/Info.plist
codesign --verify --deep --strict dist/CowHorseClock.app
git diff --check
```

Expected: 所有测试通过，Release 构建成功，Info.plist 与签名验证成功，无空白错误。

- [ ] **Step 5: 提交**

```bash
git add Sources/CowHorseClock/Features/Dashboard/DashboardView.swift \
  Tests/CowHorseClockTests/DashboardSourceTests.swift \
  Tests/CowHorseClockTests/AllTests.swift scripts/test.sh
git commit -m "feat: refresh quit button styling"
```
