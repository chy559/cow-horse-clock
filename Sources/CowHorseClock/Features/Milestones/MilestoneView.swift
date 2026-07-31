import SwiftUI

struct MilestoneView: View {
    @EnvironmentObject private var milestones: MilestoneModel

    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .frame(width: 30, height: 30)
                        .softPunchCard(fill: .punchMint, radius: 12)
                }
                .buttonStyle(.plain)
                .hoverLift(.compact)

                Spacer()

                Text("LIFE EVENTS")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(Color.punchCream)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color.punchInk)
                    .rotationEffect(.degrees(1))
            }

            Text("\(milestones.milestones.count) 条人生大事")
                .font(.system(size: 18, weight: .black, design: .rounded))
        }
        .padding(18)
        .frame(width: 360, height: 560)
        .background(Color.punchCream)
        .foregroundStyle(Color.punchInk)
    }
}
