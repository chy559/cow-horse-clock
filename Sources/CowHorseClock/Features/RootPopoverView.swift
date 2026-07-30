import SwiftUI

struct RootPopoverView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Group {
            switch model.route {
            case .dashboard:
                DashboardView()
            case .ledger:
                LedgerView()
            case .settings:
                SettingsView(isOnboarding: model.settings.trackingStartDate == nil)
            case .calendar:
                WorkCalendarView()
            }
        }
        .id(model.route)
        .transition(.opacity.combined(with: .scale(scale: 0.985)))
        .animation(.easeOut(duration: 0.16), value: model.route)
    }
}
