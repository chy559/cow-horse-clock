import AppKit
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var model: AppModel

    private var snapshot: EarningsSnapshot { model.snapshot }

    private var monthTotalCents: Decimal {
        let settled = model.monthSummary(containing: Date()).settledCents
        return Decimal(settled) + snapshot.earnedCents
    }

    private var statusText: String {
        switch snapshot.state {
        case .beforeWork:
            "工位引擎尚未点火"
        case .workingMorning, .workingAfternoon:
            "每秒回血 \(MoneyFormatter.rate(centsPerSecond: snapshot.rateCentsPerSecond))"
        case .lunch:
            "暂停燃烧生命"
        case .finished:
            "今日自由已到账"
        case .restDay:
            "今天不当牛马"
        }
    }

    private var countdownText: String {
        let time = MoneyFormatter.duration(seconds: snapshot.secondsUntilNextTransition)
        return switch snapshot.state {
        case .beforeWork:
            "距离工位点火 \(time)"
        case .workingMorning:
            "距离午休放风 \(time)"
        case .lunch:
            "距离下午开工 \(time)"
        case .workingAfternoon:
            "再坚持 \(time) 就自由了"
        case .finished:
            "今天的时间已经赎回"
        case .restDay:
            "休息也是一种生产力"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            hero
            PunchCardGauge(progress: snapshot.progress)
                .frame(height: 122)
                .padding(.horizontal, 26)
            Text(countdownText)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .padding(.top, 3)
            stats
                .padding(.top, 16)
            footer
                .padding(.top, 14)
        }
        .padding(18)
        .frame(width: 360)
        .background(Color.punchCream)
        .foregroundStyle(Color.punchInk)
    }

    private var header: some View {
        HStack {
            Text("COW HORSE CLOCK")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(Color.punchCream)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Color.punchInk)
                .rotationEffect(.degrees(-1.2))

            Spacer()

            Button {
                model.route = .settings
            } label: {
                Image(systemName: "gearshape.fill")
                    .frame(width: 30, height: 30)
                    .background(Color.punchCoral)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                    .overlay {
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(Color.punchInk, lineWidth: 2)
                    }
            }
            .buttonStyle(.plain)
            .hoverLift(.compact)
            .help("工位参数")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("今天已经为老板创造")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.punchInk.opacity(0.62))
            Text(MoneyFormatter.yuan(cents: snapshot.earnedCents))
                .font(.system(size: 38, weight: .black, design: .monospaced))
                .tracking(-2)
                .contentTransition(.numericText())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.68)
            HStack(spacing: 6) {
                Circle()
                    .fill(
                        snapshot.state == .workingMorning
                            || snapshot.state == .workingAfternoon
                            ? Color.punchCoral : Color.punchInk.opacity(0.35)
                    )
                    .frame(width: 7, height: 7)
                Text(statusText)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.punchInk.opacity(0.65))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
    }

    private var stats: some View {
        HStack(spacing: 10) {
            statCard(
                label: "搬砖进度",
                value: "\(Int(snapshot.progress * 100))%",
                fill: .punchCoral
            )
            statCard(
                label: "本月累计",
                value: MoneyFormatter.yuan(cents: monthTotalCents),
                fill: .punchPaper
            )
        }
    }

    private func statCard(label: String, value: String, fill: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
            Text(value)
                .font(.system(size: 16, weight: .black, design: .monospaced))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .punchCard(fill: fill, radius: 12)
        .hoverLift()
    }

    private var footer: some View {
        HStack {
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("收工", systemImage: "power")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .punchCard(fill: .punchCoral, radius: 9)
                    .rotationEffect(.degrees(-0.7))
            }
            .buttonStyle(.plain)
            .hoverLift(.compact)
            .help("退出 CowHorseClock")

            Spacer()

            Button {
                model.route = .ledger
            } label: {
                HStack(spacing: 4) {
                    Text("查看搬砖账本")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 11, weight: .black, design: .rounded))
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .punchCard(fill: .punchPaper, radius: 9)
            }
            .buttonStyle(.plain)
            .hoverLift(.compact)
        }
    }
}
