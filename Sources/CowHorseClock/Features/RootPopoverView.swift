import SwiftUI

struct RootPopoverView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        DashboardView()
            .id(model.route)
    }
}
