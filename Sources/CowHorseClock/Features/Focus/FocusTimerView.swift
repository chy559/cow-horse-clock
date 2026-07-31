import SwiftUI

struct FocusTimerView: View {
    @EnvironmentObject private var focus: FocusTimerModel

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

                Text("FOCUS MODE")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(Color.punchCream)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color.punchInk)
                    .rotationEffect(.degrees(1))
            }

            Text("\(focus.selectedMinutes) 分钟")
                .font(.system(size: 30, weight: .black, design: .monospaced))
        }
        .padding(18)
        .frame(width: 360, height: 500)
        .background(Color.punchCream)
        .foregroundStyle(Color.punchInk)
    }
}
