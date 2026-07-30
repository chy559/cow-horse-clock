# 牛马时钟

一款有点荒诞、但计算很认真的 macOS 菜单栏应用。

设置日薪和每天的工作时间后，牛马时钟会在有效工作时段内实时显示“今天已经赚了多少钱”。午休、下班和休息日自动暂停；历史账本、手动休息日和加班日都只保存在本机。

## 功能

- 菜单栏紧凑弹窗，失焦自动收起。
- 今日收入按墙钟时间实时重算，不怕休眠、退出或计时器延迟。
- 上午和下午两个独立计薪时段，午休不计薪。
- 今日进度、当前每秒收入和下一节点倒计时。
- 本月累计、历史总计、每日账本和月度柱状图。
- 默认工作日与手动休息/加班日覆盖。
- 修改薪资不会回溯改写已结算记录。
- 可选登录时启动。
- punch-card 风格的奶油黄、黑色粗描边和橙红强调色 UI。

## 直接使用

系统要求：macOS 14 Sonoma 或更高版本。

构建完成后双击：

```text
dist/CowHorseClock.app
```

也可以把 `CowHorseClock.app` 拖入“应用程序”文件夹。应用使用 ad-hoc 本地签名，不上传、不联网，也不需要账户。

首次启动时填写日薪、上午与下午工作时间和默认工作日。之后点击菜单栏仪表图标即可查看。

## 构建

项目使用系统 Swift Package Manager，不依赖第三方包。当前仓库包含兼容只安装 Apple Command Line Tools 的构建脚本：

```bash
bash scripts/test.sh
bash scripts/build-app.sh
open dist/CowHorseClock.app
```

`scripts/test.sh` 会直接编译并运行轻量 Swift 测试套件。`scripts/build-app.sh` 会编译 Release 可执行文件、组装标准 `.app` bundle，并完成 ad-hoc 签名。

## 本地数据

当前设置、工作日历和每日账本以 Codable JSON 保存在应用自己的 macOS 偏好域：

```text
com.local.CowHorseClock
```

应用不会请求网络权限，也不会把薪资或工作记录发送到其他位置。
