import Foundation

@main
struct AllTests {
    @MainActor
    static func main() {
        let tests =
            workSettingsTests
            + earningsEngineTests
            + ledgerStoreTests
            + appModelTests
            + moneyFormatterTests
            + hoverLiftStyleTests
            + dashboardSourceTests
            + secondaryViewSourceTests
            + focusTimerTests
        var failures = 0

        for test in tests {
            do {
                try test.run()
                print("PASS \(test.name)")
            } catch {
                failures += 1
                print("FAIL \(test.name): \(error)")
            }
        }

        print("\(tests.count - failures) passed, \(failures) failed")
        if failures > 0 {
            exit(1)
        }
    }
}
