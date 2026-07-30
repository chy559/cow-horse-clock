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
    }
]
