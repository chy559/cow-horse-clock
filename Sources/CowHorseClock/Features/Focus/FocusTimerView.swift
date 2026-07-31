import SwiftUI

struct FocusTimerView: View {
    @EnvironmentObject private var focus: FocusTimerModel

    let onBack: () -> Void

    private var remainingText: String {
        let seconds = max(0, Int(ceil(focus.remainingSeconds)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private var statusTitle: String {
        switch focus.phase {
        case .idle:
            "准备进入心流"
        case .running:
            "专注进行中"
        case .paused:
            "暂时停一下"
        case .completed:
            "本轮专注完成"
        }
    }

    private var statusDetail: String {
        switch focus.phase {
        case .idle:
            "选好时长，暂时把世界静音"
        case .running:
            "这一小段时间，只做眼前这一件事"
        case .paused:
            "喘口气，准备好再继续"
        case .completed:
            "漂亮，又完整拿下一段时间"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            timerRing
                .padding(.top, 14)
            status
                .padding(.top, 8)
            configurationArea
                .padding(.top, 14)
            actions
                .padding(.top, 16)
        }
        .padding(18)
        .frame(width: 360, height: 500)
        .background(Color.punchCream)
        .foregroundStyle(Color.punchInk)
    }

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .frame(width: 30, height: 30)
                    .softPunchCard(fill: .punchMint, radius: 12)
            }
            .buttonStyle(.plain)
            .hoverLift(.compact)
            .help("返回仪表盘")

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
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.78), lineWidth: 18)

            Circle()
                .trim(from: 0, to: max(0.001, focus.progress))
                .stroke(
                    AngularGradient(
                        colors: [.punchCoral, .punchMint, .punchCoral],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 13, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.2), value: focus.progress)

            VStack(spacing: 5) {
                Text(focus.phase == .running ? "剩余时间" : "专注时间")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.punchInk.opacity(0.55))
                Text(remainingText)
                    .font(.system(size: 36, weight: .black, design: .monospaced))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("\(focus.selectedMinutes) 分钟一轮")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.punchInk.opacity(0.5))
            }
        }
        .frame(width: 184, height: 184)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(statusTitle)
        .accessibilityValue(remainingText)
    }

    private var status: some View {
        VStack(spacing: 3) {
            Text(statusTitle)
                .font(.system(size: 14, weight: .black, design: .rounded))
            Text(statusDetail)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.punchInk.opacity(0.58))
        }
    }

    @ViewBuilder
    private var configurationArea: some View {
        if focus.phase == .idle || focus.phase == .completed {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    presetButton(minutes: 15)
                    presetButton(minutes: 25)
                    presetButton(minutes: 45)
                    presetButton(minutes: 60)
                }

                HStack(spacing: 12) {
                    adjustmentButton(systemName: "minus", minutes: -5)
                        .disabled(
                            focus.selectedMinutes
                                <= FocusTimerModel.minuteRange.lowerBound
                        )
                    Text("\(focus.selectedMinutes) 分钟")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .frame(minWidth: 90)
                    adjustmentButton(systemName: "plus", minutes: 5)
                        .disabled(
                            focus.selectedMinutes
                                >= FocusTimerModel.minuteRange.upperBound
                        )
                }
            }
            .frame(height: 82)
        } else {
            HStack(spacing: 8) {
                Image(systemName: focus.phase == .running ? "flame.fill" : "pause.fill")
                    .foregroundStyle(Color.punchCoral)
                Text(
                    focus.phase == .running
                        ? "计时会在面板收起后继续"
                        : "剩余时间已经为你保留"
                )
                .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .softPunchCard(fill: .punchPaper, radius: 18)
            .hoverLift()
            .frame(height: 82)
        }
    }

    private func presetButton(minutes: Int) -> some View {
        Button {
            focus.select(minutes: minutes)
        } label: {
            Text("\(minutes)")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .softPunchCard(
                    fill: focus.selectedMinutes == minutes
                        ? .punchCoral : .punchPaper,
                    radius: 12
                )
        }
        .buttonStyle(.plain)
        .hoverLift(.compact)
    }

    private func adjustmentButton(
        systemName: String,
        minutes: Int
    ) -> some View {
        Button {
            focus.adjustMinutes(by: minutes)
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .black))
                .frame(width: 30, height: 28)
                .softPunchCard(fill: .punchMint, radius: 12)
        }
        .buttonStyle(.plain)
        .hoverLift(.compact)
        .opacity(
            (minutes < 0
                && focus.selectedMinutes <= FocusTimerModel.minuteRange.lowerBound)
                || (minutes > 0
                    && focus.selectedMinutes >= FocusTimerModel.minuteRange.upperBound)
                ? 0.35 : 1
        )
    }

    @ViewBuilder
    private var actions: some View {
        switch focus.phase {
        case .idle:
            primaryAction(title: "开始专注", systemName: "play.fill") {
                focus.start()
            }
        case .running:
            HStack(spacing: 10) {
                secondaryAction(title: "暂停", systemName: "pause.fill") {
                    focus.pause()
                }
                secondaryAction(title: "结束本轮", systemName: "xmark") {
                    focus.reset()
                }
            }
        case .paused:
            HStack(spacing: 10) {
                primaryAction(title: "继续", systemName: "play.fill") {
                    focus.resume()
                }
                secondaryAction(title: "结束本轮", systemName: "xmark") {
                    focus.reset()
                }
            }
        case .completed:
            HStack(spacing: 10) {
                primaryAction(title: "再来一轮", systemName: "arrow.clockwise") {
                    focus.start()
                }
                secondaryAction(title: "结束", systemName: "checkmark") {
                    focus.reset()
                }
            }
        }
    }

    private func primaryAction(
        title: String,
        systemName: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemName)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.punchInk)
                .foregroundStyle(Color.punchCream)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .hoverLift()
    }

    private func secondaryAction(
        title: String,
        systemName: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemName)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .softPunchCard(fill: .punchPaper, radius: 14)
        }
        .buttonStyle(.plain)
        .hoverLift()
    }
}
