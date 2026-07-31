import Foundation

let dashboardSourceTests: [TestCase] = [
    TestCase(name: "quit button keeps the punch-card visual treatment") {
        let testsDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let projectDirectory = testsDirectory.deletingLastPathComponent()
        let dashboardURL = projectDirectory
            .appendingPathComponent(
                "Sources/CowHorseClock/Features/Dashboard/DashboardView.swift"
            )
        let source = try String(contentsOf: dashboardURL, encoding: .utf8)
        guard let footerRange = source.range(of: "private var footer") else {
            throw TestFailure(description: "Dashboard footer not found")
        }
        let footer = source[footerRange.lowerBound...]
        let quitButton = footer.components(separatedBy: "Spacer()")[0]

        try expect(
            quitButton.contains(".punchCard(fill: .punchCoral, radius: 9)"),
            "quit button should use a coral punch card"
        )
        try expect(
            quitButton.contains(".hoverLift(.compact)"),
            "quit button should use the compact hover lift"
        )
        try expect(
            quitButton.contains(".help(\"退出 CowHorseClock\")"),
            "quit button should explain that it exits the app"
        )
    },
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
        guard
            let amountStart = hero.range(
                of: "Text(MoneyFormatter.yuan(cents: snapshot.earnedCents))"
            ),
            let statusStart = hero.range(of: "HStack(spacing: 6)")
        else {
            throw TestFailure(description: "Dashboard hero amount not found")
        }
        let amount = hero[amountStart.lowerBound..<statusStart.lowerBound]

        try expect(
            !amount.contains(".tracking("),
            "hero earnings text must not use negative tracking"
        )
    },
    TestCase(name: "hero caption uses the approved copy") {
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
            hero.contains("Text(\"今天已回血\")"),
            "hero caption should use the approved copy"
        )
        try expect(
            !hero.contains("今天已经为老板创造"),
            "hero caption should not keep the previous copy"
        )
    }
]
