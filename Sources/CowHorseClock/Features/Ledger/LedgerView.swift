import Charts
import SwiftUI

private struct DailyBar: Identifiable {
    let id: String
    let label: String
    let amountYuan: Double
    let isToday: Bool
}

struct LedgerView: View {
    @EnvironmentObject private var model: AppModel
    @State private var displayedMonth = Calendar.current.date(
        from: Calendar.current.dateComponents([.year, .month], from: Date())
    ) ?? Date()

    private var summary: MonthSummary {
        model.monthSummary(containing: displayedMonth)
    }

    private var showsToday: Bool {
        Calendar.current.isDate(displayedMonth, equalTo: Date(), toGranularity: .month)
    }

    private var currentCents: Decimal {
        showsToday ? model.snapshot.earnedCents : .zero
    }

    private var bars: [DailyBar] {
        var values = summary.records.compactMap { record -> DailyBar? in
            guard let date = model.ledgerStore.date(fromKey: record.dateKey) else {
                return nil
            }
            return DailyBar(
                id: record.dateKey,
                label: "\(Calendar.current.component(.day, from: date))",
                amountYuan: Double(record.earnedCents) / 100,
                isToday: false
            )
        }
        if showsToday {
            let day = Calendar.current.component(.day, from: Date())
            values.append(
                DailyBar(
                    id: "today",
                    label: "\(day)",
                    amountYuan: NSDecimalNumber(
                        decimal: model.snapshot.earnedCents / Decimal(100)
                    ).doubleValue,
                    isToday: true
                )
            )
        }
        return values.sorted { (Int($0.label) ?? 0) < (Int($1.label) ?? 0) }
    }

    var body: some View {
        VStack(spacing: 14) {
            header
            totalCard
            chart
            recentRecords
            footer
        }
        .padding(18)
        .frame(width: 360, height: 560)
        .background(Color.punchCream)
        .foregroundStyle(Color.punchInk)
    }

    private var header: some View {
        HStack {
            Button {
                model.route = .dashboard
            } label: {
                Image(systemName: "arrow.left")
                    .frame(width: 28, height: 28)
                    .punchCard(fill: .punchCoral, radius: 9)
            }
            .buttonStyle(.plain)
            .hoverLift(.compact)

            Spacer()

            Button {
                changeMonth(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 26, height: 26)
                    .punchCard(fill: .punchPaper, radius: 8)
            }
            .buttonStyle(.plain)
            .hoverLift(.compact)

            Text(monthTitle)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .frame(width: 105)

            Button {
                changeMonth(1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 26, height: 26)
                    .punchCard(fill: .punchPaper, radius: 8)
            }
            .buttonStyle(.plain)
            .hoverLift(.compact)
            .disabled(isCurrentMonth)
            .opacity(isCurrentMonth ? 0.3 : 1)

            Spacer()

            Text("搬砖账本")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .background(Color.punchInk)
                .foregroundStyle(Color.punchCream)
                .rotationEffect(.degrees(1.4))
        }
    }

    private var totalCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("本月累计")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color.punchInk.opacity(0.6))
            Text(
                MoneyFormatter.yuan(
                    cents: Decimal(summary.settledCents) + currentCents
                )
            )
            .font(.system(size: 28, weight: .black, design: .monospaced))
            .monospacedDigit()
            Text("钱是一天一天熬出来的")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .punchCard(fill: .punchPaper)
        .hoverLift()
    }

    private var chart: some View {
        Chart(bars) { item in
            BarMark(
                x: .value("日期", item.label),
                y: .value("收入", item.amountYuan)
            )
            .foregroundStyle(item.isToday ? Color.punchCoral : Color.punchInk)
            .cornerRadius(3)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 7)) {
                AxisValueLabel()
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                AxisGridLine().foregroundStyle(.clear)
                AxisTick().foregroundStyle(.clear)
            }
        }
        .chartYAxis(.hidden)
        .frame(height: 105)
        .padding(10)
        .punchCard(fill: .punchPaper)
        .hoverLift()
    }

    private var recentRecords: some View {
        VStack(spacing: 0) {
            if showsToday {
                recordRow(
                    title: "今天 · 搬砖中",
                    amount: model.snapshot.earnedCents,
                    highlighted: true
                )
            }
            ForEach(summary.records.prefix(showsToday ? 4 : 5)) { record in
                recordRow(
                    title: recordTitle(record.dateKey),
                    amount: Decimal(record.earnedCents),
                    highlighted: false
                )
            }
            if summary.records.isEmpty && !showsToday {
                Text("这个月还没有搬砖记录")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.punchInk.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
            }
        }
        .punchCard(fill: .punchPaper)
        .hoverLift()
    }

    private func recordRow(
        title: String,
        amount: Decimal,
        highlighted: Bool
    ) -> some View {
        HStack {
            Circle()
                .fill(highlighted ? Color.punchCoral : Color.punchInk.opacity(0.18))
                .frame(width: 7, height: 7)
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
            Spacer()
            Text(MoneyFormatter.yuan(cents: amount))
                .font(.system(size: 11, weight: .black, design: .monospaced))
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.punchInk.opacity(0.12))
                .frame(height: 1)
        }
    }

    private var footer: some View {
        HStack {
            Text("历史总计")
                .font(.system(size: 10, weight: .bold, design: .rounded))
            Spacer()
            Text(
                MoneyFormatter.yuan(
                    cents: Decimal(model.historicalTotalCents) + model.snapshot.earnedCents
                )
            )
            .font(.system(size: 13, weight: .black, design: .monospaced))
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: displayedMonth)
    }

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(displayedMonth, equalTo: Date(), toGranularity: .month)
    }

    private func recordTitle(_ key: String) -> String {
        guard let date = model.ledgerStore.date(fromKey: key) else { return key }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M 月 d 日"
        return formatter.string(from: date)
    }

    private func changeMonth(_ value: Int) {
        displayedMonth =
            Calendar.current.date(byAdding: .month, value: value, to: displayedMonth)
            ?? displayedMonth
    }
}
