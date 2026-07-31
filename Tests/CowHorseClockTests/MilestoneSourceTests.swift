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
    },
    TestCase(name: "milestone page provides categorized event editing") {
        let source = try milestoneSource(
            "Sources/CowHorseClock/Features/Milestones/MilestoneView.swift"
        )

        try expect(
            source.contains("ForEach(MilestoneCategory.allCases)"),
            "page should expose all categories"
        )
        try expect(source.contains("milestones.add("), "page should add")
        try expect(source.contains("milestones.update("), "page should edit")
        try expect(source.contains("milestones.delete("), "page should delete")
        try expect(source.contains("DatePicker("), "editor should select a date")
        try expect(
            source.contains("TextEditor(text: $draftNote)"),
            "editor should accept a description"
        )
        try expect(
            !source.contains("snapshot")
                && !source.contains("ledgerStore")
                && !source.contains("FocusTimerModel"),
            "milestone page should remain independent"
        )
    }
]
