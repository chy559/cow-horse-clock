# 仪表盘主金额标题文案 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将仪表盘主金额上方文案精确替换为“今天已回血”。

**Architecture:** 在现有仪表盘源码契约测试中锁定新文案并排除旧文案，再只替换 `DashboardView.hero` 中的字符串。视觉修饰器和业务逻辑保持不变。

**Tech Stack:** Swift 6、SwiftUI、macOS 14、自定义 Swift 测试运行器。

## Global Constraints

- 新文案必须精确为“今天已回血”。
- 保留现有字体、颜色、间距和布局。
- 不修改金额、计时、状态提示或其他页面文案。
- 禁止调用 `pdftotext`。

---

### Task 1: 替换主金额标题

**Files:**
- Modify: `Tests/CowHorseClockTests/DashboardSourceTests.swift`
- Modify: `Sources/CowHorseClock/Features/Dashboard/DashboardView.swift`

**Interfaces:**
- Consumes: `DashboardView.hero`
- Produces: 固定显示“今天已回血”的主金额标题

- [ ] **Step 1: 写失败的文案契约测试**

在 `dashboardSourceTests` 中新增测试，提取 `private var hero` 到 `private var stats`，并断言：

```swift
try expect(
    hero.contains("Text(\"今天已回血\")"),
    "hero caption should use the approved copy"
)
try expect(
    !hero.contains("今天已经为老板创造"),
    "hero caption should not keep the previous copy"
)
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `bash scripts/test.sh`

Expected: FAIL，输出 `hero caption should use the approved copy`。

- [ ] **Step 3: 实现最小替换**

把：

```swift
Text("今天已经为老板创造")
```

替换为：

```swift
Text("今天已回血")
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

Expected: 全部测试通过，Release 构建成功，Info.plist 与签名有效。

- [ ] **Step 5: 提交**

```bash
git add Tests/CowHorseClockTests/DashboardSourceTests.swift \
  Sources/CowHorseClock/Features/Dashboard/DashboardView.swift
git commit -m "feat: update hero caption copy"
```
