import Foundation

private func milestoneSource(_ relativePath: String) throws -> String {
    let testsDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let projectDirectory = testsDirectory.deletingLastPathComponent()
    return try String(
        contentsOf: projectDirectory.appendingPathComponent(relativePath),
        encoding: .utf8
    )
}

let milestoneSourceTests: [TestCase] = [
    TestCase(name: "milestones have independent navigation and ownership") {
        let appModelSource = try milestoneSource(
            "Sources/CowHorseClock/AppModel.swift"
        )
        let rootSource = try milestoneSource(
            "Sources/CowHorseClock/Features/RootPopoverView.swift"
        )
        let dashboardSource = try milestoneSource(
            "Sources/CowHorseClock/Features/Dashboard/DashboardView.swift"
        )
        let appSource = try milestoneSource(
            "Sources/CowHorseClock/CowHorseClockApp.swift"
        )

        try expect(
            appModelSource.contains("case milestones"),
            "app route should include milestones"
        )
        try expect(
            rootSource.contains("case .milestones:")
                && rootSource.contains("MilestoneView("),
            "root should route to milestones"
        )
        try expect(
            dashboardSource.contains("model.route = .milestones")
                && dashboardSource.contains(
                    "Image(systemName: \"flag.fill\")"
                ),
            "dashboard should expose milestones"
        )
        try expect(
            appSource.contains("@StateObject private var milestoneModel")
                && appSource.contains(".environmentObject(milestoneModel)"),
            "app should inject milestone model"
        )
    }
]
