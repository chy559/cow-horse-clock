import SwiftUI

struct WorkCalendarView: View {
    @EnvironmentObject private var model: AppModel
    @State private var displayedMonth = Calendar.current.date(
        from: Calendar.current.dateComponents([.year, .month], from: Date())
    ) ?? Date()
    @State private var errorMessage: String?

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 5),
        count: 7
    )
    private let weekdayTitles = ["一", "二", "三", "四", "五", "六", "日"]

    var body: some View {
        VStack(spacing: 15) {
            header
            weekdayHeader
            calendarGrid
            legend
            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.red)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(width: 360, height: 480)
        .background(Color.punchCream)
        .foregroundStyle(Color.punchInk)
    }

    private var header: some View {
        HStack {
            Button {
                model.route = .settings
            } label: {
                Image(systemName: "arrow.left")
                    .frame(width: 28, height: 28)
                    .punchCard(fill: .punchCoral, radius: 9)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                changeMonth(-1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Text(monthTitle)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .frame(width: 105)

            Button {
                changeMonth(1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)

            Spacer()

            Text("排班簿")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .background(Color.punchInk)
                .foregroundStyle(Color.punchCream)
                .rotationEffect(.degrees(1.4))
        }
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(weekdayTitles, id: \.self) { title in
                Text(title)
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(Color.punchInk.opacity(0.55))
            }
        }
    }

    private var calendarGrid: some View {
        let _ = model.ledgerRevision
        return LazyVGrid(columns: columns, spacing: 7) {
            ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                if let date {
                    dayButton(date)
                } else {
                    Color.clear.frame(height: 38)
                }
            }
        }
        .padding(10)
        .punchCard(fill: .punchPaper, radius: 16)
    }

    private func dayButton(_ date: Date) -> some View {
        let kind = model.ledgerStore.overrideKind(on: date)
        let isDefaultWorkday = model.settings.defaultWeekdays.contains(
            Calendar.current.component(.weekday, from: date)
        )
        let number = Calendar.current.component(.day, from: date)

        return Button {
            cycleOverride(kind, on: date)
        } label: {
            ZStack {
                Circle()
                    .fill(dayFill(kind: kind, isDefaultWorkday: isDefaultWorkday))
                    .overlay {
                        Circle().stroke(
                            kind == nil ? Color.clear : Color.punchInk,
                            lineWidth: 2
                        )
                    }
                Text("\(number)")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .strikethrough(kind == .rest, color: .punchInk)
            }
            .frame(height: 38)
        }
        .buttonStyle(.plain)
        .help(dayHelp(kind))
    }

    private var legend: some View {
        HStack(spacing: 13) {
            legendItem("默认工作", color: .punchCream)
            legendItem("休息", color: .gray.opacity(0.32))
            legendItem("加班", color: .punchCoral)
        }
        .font(.system(size: 9, weight: .bold, design: .rounded))
    }

    private func legendItem(_ label: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .overlay { Circle().stroke(Color.punchInk, lineWidth: 1) }
                .frame(width: 10, height: 10)
            Text(label)
        }
    }

    private func dayFill(
        kind: CalendarOverrideKind?,
        isDefaultWorkday: Bool
    ) -> Color {
        switch kind {
        case .rest:
            Color.gray.opacity(0.32)
        case .work:
            Color.punchCoral
        case nil:
            isDefaultWorkday ? Color.punchCream : Color.clear
        }
    }

    private func dayHelp(_ kind: CalendarOverrideKind?) -> String {
        switch kind {
        case nil: "点击标记为休息日"
        case .rest: "点击标记为加班日"
        case .work: "点击恢复默认排班"
        }
    }

    private func cycleOverride(_ kind: CalendarOverrideKind?, on date: Date) {
        let next: CalendarOverrideKind? = switch kind {
        case nil: .rest
        case .rest: .work
        case .work: nil
        }
        do {
            try model.setOverride(next, on: date)
            errorMessage = nil
        } catch {
            errorMessage = "日历标记保存失败"
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: displayedMonth)
    }

    private var monthCells: [Date?] {
        let calendar = Calendar.current
        guard
            let range = calendar.range(of: .day, in: .month, for: displayedMonth),
            let first = calendar.date(
                from: calendar.dateComponents([.year, .month], from: displayedMonth)
            )
        else {
            return []
        }
        let weekday = calendar.component(.weekday, from: first)
        let mondayOffset = (weekday + 5) % 7
        var values = Array<Date?>(repeating: nil, count: mondayOffset)
        values += range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: first)
        }
        while !values.count.isMultiple(of: 7) {
            values.append(nil)
        }
        return values
    }

    private func changeMonth(_ value: Int) {
        displayedMonth =
            Calendar.current.date(byAdding: .month, value: value, to: displayedMonth)
            ?? displayedMonth
    }
}
