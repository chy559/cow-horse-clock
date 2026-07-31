import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    let isOnboarding: Bool

    @State private var draft = WorkSettings.default
    @State private var salaryText = "400.00"
    @State private var saveError: String?

    private let weekdays: [(Int, String)] = [
        (2, "一"), (3, "二"), (4, "三"), (5, "四"),
        (6, "五"), (7, "六"), (1, "日")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if isOnboarding {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("先录入你的工位参数")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                        Text("设置完成后，时间就会开始变成钱。")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.punchInk.opacity(0.62))
                    }
                }

                fieldGroup("每日薪资") {
                    HStack {
                        Text("¥")
                            .font(.system(size: 17, weight: .black, design: .monospaced))
                        TextField("400.00", text: $salaryText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 17, weight: .black, design: .monospaced))
                            .multilineTextAlignment(.trailing)
                        Text("人民币")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.punchInk.opacity(0.5))
                    }
                    .padding(11)
                    .softPunchCard(radius: 18)
                }

                fieldGroup("上午计薪") {
                    timeRangeRow(
                        start: timeBinding(\.morning, start: true),
                        end: timeBinding(\.morning, start: false)
                    )
                }

                fieldGroup("下午计薪") {
                    timeRangeRow(
                        start: timeBinding(\.afternoon, start: true),
                        end: timeBinding(\.afternoon, start: false)
                    )
                }

                fieldGroup("默认工作日") {
                    HStack(spacing: 7) {
                        ForEach(weekdays, id: \.0) { value, label in
                            Button {
                                if draft.defaultWeekdays.contains(value) {
                                    draft.defaultWeekdays.remove(value)
                                } else {
                                    draft.defaultWeekdays.insert(value)
                                }
                            } label: {
                                Text(label)
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .frame(width: 28, height: 28)
                                    .background(
                                        draft.defaultWeekdays.contains(value)
                                            ? Color.punchCoral : Color.punchPaper
                                    )
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle().stroke(Color.punchInk, lineWidth: 2)
                                    }
                            }
                            .buttonStyle(.plain)
                            .hoverLift(.compact)
                        }
                    }
                }

                Toggle(isOn: $draft.launchAtLogin) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("登录时启动")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                        Text("每天开机自动点火")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.punchInk.opacity(0.55))
                    }
                }
                .toggleStyle(.switch)
                .tint(.punchCoral)
                .padding(11)
                .softPunchCard(fill: .punchPaper, radius: 18)

                if !isOnboarding {
                    Button {
                        model.route = .calendar
                    } label: {
                        HStack {
                            Label("工作日历", systemImage: "calendar")
                            Spacer()
                            Text("标记休息 / 加班")
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .padding(11)
                        .softPunchCard(fill: .punchPaper, radius: 18)
                    }
                    .buttonStyle(.plain)
                    .hoverLift()
                }

                validationMessages

                Button(action: save) {
                    Text(isOnboarding ? "开始把时间变成钱" : "保存工位参数")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.punchInk)
                        .foregroundStyle(Color.punchCream)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .hoverLift()
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.42)
            }
            .padding(18)
        }
        .frame(width: 360, height: isOnboarding ? 590 : 610)
        .background(Color.punchCream)
        .foregroundStyle(Color.punchInk)
        .onAppear(perform: loadDraft)
    }

    private var header: some View {
        HStack {
            if !isOnboarding {
                backButton
            }
            Text(isOnboarding ? "FIRST SHIFT" : "工位参数")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(1.2)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.punchInk)
                .foregroundStyle(Color.punchCream)
                .rotationEffect(.degrees(-1))
            Spacer()
            if !isOnboarding {
                Button {
                    model.route = .dashboard
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .black))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var backButton: some View {
        Button {
            model.route = .dashboard
        } label: {
            Image(systemName: "arrow.left")
                .font(.system(size: 12, weight: .black))
                .frame(width: 28, height: 28)
                .softPunchCard(fill: .punchCoral, radius: 12)
        }
        .buttonStyle(.plain)
        .hoverLift(.compact)
    }

    private var canSave: Bool {
        parsedSalaryCents != nil && candidateValidationErrors.isEmpty
    }

    @ViewBuilder
    private var validationMessages: some View {
        let messages = candidateValidationErrors.map(\.message)
        if !messages.isEmpty || parsedSalaryCents == nil || saveError != nil {
            VStack(alignment: .leading, spacing: 4) {
                if parsedSalaryCents == nil {
                    Text("• 请输入有效的每日薪资")
                }
                ForEach(messages, id: \.self) { message in
                    Text("• \(message)")
                }
                if let saveError {
                    Text("• \(saveError)")
                }
            }
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(Color.red.opacity(0.78))
        }
    }

    private func fieldGroup<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(1)
            content()
        }
    }

    private func timeRangeRow(
        start: Binding<Date>,
        end: Binding<Date>
    ) -> some View {
        HStack {
            DatePicker("", selection: start, displayedComponents: .hourAndMinute)
                .labelsHidden()
            Spacer()
            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .black))
            Spacer()
            DatePicker("", selection: end, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
        .padding(8)
        .softPunchCard(radius: 18)
    }

    private func timeBinding(
        _ keyPath: WritableKeyPath<WorkSettings, TimeRange>,
        start: Bool
    ) -> Binding<Date> {
        Binding(
            get: {
                let range = draft[keyPath: keyPath]
                return dateForMinute(start ? range.startMinute : range.endMinute)
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                let minute = (components.hour ?? 0) * 60 + (components.minute ?? 0)
                if start {
                    draft[keyPath: keyPath].startMinute = minute
                } else {
                    draft[keyPath: keyPath].endMinute = minute
                }
            }
        )
    }

    private func dateForMinute(_ minute: Int) -> Date {
        Calendar.current.date(
            from: DateComponents(
                year: 2001,
                month: 1,
                day: 1,
                hour: minute / 60,
                minute: minute % 60
            )
        ) ?? Date()
    }

    private var parsedSalaryCents: Int64? {
        SalaryInputParser.cents(from: salaryText)
    }

    private var candidateValidationErrors: [SettingsValidationError] {
        guard let cents = parsedSalaryCents else {
            return draft.validationErrors
        }
        var candidate = draft
        candidate.dailySalaryCents = cents
        return candidate.validationErrors
    }

    private func loadDraft() {
        draft = model.settings
        salaryText = String(
            MoneyFormatter.yuan(cents: Decimal(draft.dailySalaryCents)).dropFirst()
        )
        saveError = nil
    }

    private func save() {
        guard let cents = parsedSalaryCents else { return }
        draft.dailySalaryCents = cents
        do {
            if isOnboarding {
                try model.completeSetup(draft)
            } else {
                try model.saveSettings(draft)
                model.route = .dashboard
            }
            saveError = nil
        } catch {
            saveError = "保存失败，请检查登录启动权限后重试"
        }
    }
}

private extension SettingsValidationError {
    var message: String {
        switch self {
        case .negativeSalary:
            "每日薪资不能小于零"
        case .invalidMorningRange:
            "上午结束时间必须晚于开始时间"
        case .invalidAfternoonRange:
            "下午结束时间必须晚于开始时间"
        case .rangesOverlap:
            "上午工作不能与下午工作重叠"
        case .noWorkday:
            "至少选择一个默认工作日"
        }
    }
}
