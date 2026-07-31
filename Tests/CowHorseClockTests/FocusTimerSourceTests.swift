import Foundation

private func focusSource(_ relativePath: String) throws -> String {
    let testsDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let projectDirectory = testsDirectory.deletingLastPathComponent()
    return try String(
        contentsOf: projectDirectory.appendingPathComponent(relativePath),
        encoding: .utf8
    )
}

let focusTimerSourceTests: [TestCase] = [
    TestCase(name: "focus timer has independent navigation and ownership") {
        let appModelSource = try focusSource(
            "Sources/CowHorseClock/AppModel.swift"
        )
        let rootSource = try focusSource(
            "Sources/CowHorseClock/Features/RootPopoverView.swift"
        )
        let dashboardSource = try focusSource(
            "Sources/CowHorseClock/Features/Dashboard/DashboardView.swift"
        )
        let appSource = try focusSource(
            "Sources/CowHorseClock/CowHorseClockApp.swift"
        )

        try expect(
            appModelSource.contains("case focus"),
            "app route should include focus"
        )
        try expect(
            rootSource.contains("case .focus:")
                && rootSource.contains("FocusTimerView("),
            "root popover should route to the focus page"
        )
        try expect(
            dashboardSource.contains("model.route = .focus")
                && dashboardSource.contains("Image(systemName: \"timer\")"),
            "dashboard should expose a focus timer entry"
        )
        try expect(
            appSource.contains("@StateObject private var focusTimer")
                && appSource.contains(".environmentObject(focusTimer)"),
            "app should own and inject the independent focus timer"
        )
    }
]
