import Foundation

let secondaryViewSourceTests: [TestCase] = [
    TestCase(name: "ledger cards use soft gradients and rounder corners") {
        let testsDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let projectDirectory = testsDirectory.deletingLastPathComponent()
        let ledgerURL = projectDirectory.appendingPathComponent(
            "Sources/CowHorseClock/Features/Ledger/LedgerView.swift"
        )
        let source = try String(contentsOf: ledgerURL, encoding: .utf8)

        try expect(
            source.components(
                separatedBy: ".softPunchCard(fill: .punchPaper, radius: 12)"
            ).count - 1 == 2,
            "ledger month controls should use two soft 12-point cards"
        )
        try expect(
            source.contains(".softPunchCard(fill: .punchCoral, radius: 12)"),
            "ledger back button should use a soft 12-point card"
        )
        try expect(
            source.components(
                separatedBy: ".softPunchCard(fill: .punchPaper, radius: 18)"
            ).count - 1 == 3,
            "ledger content should use three soft 18-point cards"
        )
        try expect(
            !source.contains(".punchCard("),
            "ledger should not keep hard-edged punch cards"
        )
    }
]
