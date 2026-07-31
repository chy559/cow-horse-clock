# 牛马时钟应用图标设计

## 目标

为 CowHorseClock 制作一枚专属 macOS 应用图标，替换系统默认应用图标。图标需要延续现有打卡纸 UI 的颜色与幽默感，并在访达、Dock、启动台和 16px 小尺寸中保持可辨识。

## 方向比较

1. **牛马计时表盘（采用）**：把牛角、马耳、时钟与增长指针组合成单一图形，应用定位最完整，小尺寸轮廓最鲜明。
2. **工资硬币**：金额含义明确，但容易被误认为记账或理财应用。
3. **打卡纸票据**：贴合 UI 材质，但缩小后细节容易糊成普通方块。

## 视觉设计

- 画布为标准 1024×1024 macOS 应用图标母版。
- 外形使用带透明圆角边缘的奶油黄色软方块，具有轻微纸张厚度感。
- 主体是珊瑚红圆形计时表盘，使用墨黑粗描边。
- 表盘上方左侧为短牛角、右侧为马耳，以不对称轮廓表达“牛马”。
- 中央指针形成简洁的向上折线，同时表达时间推进和累计金额增长。
- 只使用奶油黄、珊瑚红、墨黑与少量白色高光；不使用文字、货币符号或复杂刻度。
- 风格为干净的矢量感平面插画，辅以轻微硬投影，与应用内 punch-card 视觉一致。

## 资源与集成

- 保留 1024px PNG 母版。
- 生成 macOS `AppIcon.icns`，包含现代 `ic07–ic14` 的 32、64、128、256、512、1024px 图层，覆盖 16、32、128、256、512 点及 Retina 场景。由于 macOS 26 的 `iconutil` 无法重新打包其自身导出的 iconset，使用标准 ICNS 块格式写入，并用 `iconutil` 反向解包验证。
- 将资源存放于 `Resources/AppIcon.png` 与 `Resources/AppIcon.icns`。
- 构建脚本把 `AppIcon.icns` 复制到应用包 `Contents/Resources`，并在 `Info.plist` 写入 `CFBundleIconFile = AppIcon`。
- Swift Package 声明中无需把图标作为运行时资源编译；图标由打包脚本直接管理。

## 验收标准

- `dist/CowHorseClock.app/Contents/Resources/AppIcon.icns` 存在且可读取。
- `Info.plist` 包含 `CFBundleIconFile`，值为 `AppIcon`。
- 图标 PNG 为 1024×1024，透明圆角有效。
- `iconutil` 能反向解包并识别生成的 ICNS。
- 现有测试、Release 构建、Info.plist 与代码签名验证全部通过。
