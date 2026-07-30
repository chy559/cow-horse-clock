import SwiftUI

@main
struct CowHorseClockApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        MenuBarExtra(
            "牛马时钟",
            systemImage: "gauge.with.dots.needle.bottom.50percent"
        ) {
            RootPopoverView()
                .environmentObject(appModel)
        }
        .menuBarExtraStyle(.window)
    }
}
