import SwiftUI

struct MilestoneView: View {
    @EnvironmentObject private var milestones: MilestoneModel

    let onBack: () -> Void

    @State private var selectedCategory: MilestoneCategory?
    @State private var editingMilestone: Milestone?
    @State private var isCreating = false
    @State private var draftDate = Date()
    @State private var draftCategory = MilestoneCategory.life
    @State private var draftNote = ""

    private var isEditing: Bool {
        isCreating || editingMilestone != nil
    }

    private var filteredMilestones: [Milestone] {
        guard let selectedCategory else { return milestones.milestones }
        return milestones.milestones.filter { $0.category == selectedCategory }
    }

    private var thisYearCount: Int {
        milestones.milestones.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .year)
        }.count
    }

    private var cleanedDraftNote: String {
        draftNote.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Group {
            if isEditing {
                editor
            } else {
                list
            }
        }
        .padding(18)
        .frame(width: 360, height: 560)
        .background(Color.punchCream)
        .foregroundStyle(Color.punchInk)
        .animation(.easeOut(duration: 0.16), value: isEditing)
    }

    private var list: some View {
        VStack(spacing: 12) {
            listHeader
            statistics
            filters
            milestoneList
        }
    }

    private var listHeader: some View {
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

            Text("LIFE EVENTS")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(Color.punchCream)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Color.punchInk)
                .rotationEffect(.degrees(1))

            Spacer()

            Button(action: beginCreating) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .black))
                    .frame(width: 30, height: 30)
                    .softPunchCard(fill: .punchCoral, radius: 12)
            }
            .buttonStyle(.plain)
            .hoverLift(.compact)
            .help("记录一件大事")
        }
    }

    private var statistics: some View {
        HStack(spacing: 10) {
            statisticCard(
                label: "全部记录",
                value: "\(milestones.milestones.count)",
                icon: "flag.fill",
                fill: .punchCoral
            )
            statisticCard(
                label: "今年发生",
                value: "\(thisYearCount)",
                icon: "calendar",
                fill: .punchPaper
            )
        }
    }

    private func statisticCard(
        label: String,
        value: String,
        icon: String,
        fill: Color
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .black))
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.punchInk.opacity(0.58))
                Text(value)
                    .font(.system(size: 20, weight: .black, design: .monospaced))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .frame(height: 58)
        .softPunchCard(fill: fill, radius: 18)
        .hoverLift()
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                filterButton(nil)
                ForEach(MilestoneCategory.allCases) { category in
                    filterButton(category)
                }
            }
            .padding(.vertical, 5)
        }
        .frame(height: 40)
    }

    private func filterButton(_ category: MilestoneCategory?) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            selectedCategory = category
        } label: {
            HStack(spacing: 4) {
                Image(
                    systemName: category?.systemImage ?? "square.grid.2x2.fill"
                )
                Text(category?.title ?? "全部")
            }
            .font(.system(size: 9, weight: .black, design: .rounded))
            .padding(.horizontal, 9)
            .frame(height: 28)
            .softPunchCard(
                fill: isSelected ? .punchCoral : .punchPaper,
                radius: 12
            )
        }
        .buttonStyle(.plain)
        .hoverLift(.compact)
    }

    @ViewBuilder
    private var milestoneList: some View {
        if filteredMilestones.isEmpty {
            emptyState
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(filteredMilestones) { milestone in
                        milestoneCard(milestone)
                    }
                }
                .padding(.horizontal, 3)
                .padding(.vertical, 5)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(Color.punchCoral)
            Text(
                selectedCategory == nil
                    ? "还没有写下人生大事"
                    : "这个分类还没有记录"
            )
            .font(.system(size: 13, weight: .black, design: .rounded))
            Text("值得记住的时刻，从第一条开始")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.punchInk.opacity(0.52))
            Button("记录一件") {
                beginCreating()
            }
            .font(.system(size: 10, weight: .black, design: .rounded))
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .softPunchCard(fill: .punchMint, radius: 12)
            .hoverLift(.compact)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .softPunchCard(fill: .punchPaper, radius: 18)
    }

    private func milestoneCard(_ milestone: Milestone) -> some View {
        Button {
            beginEditing(milestone)
        } label: {
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: milestone.category.systemImage)
                    .font(.system(size: 13, weight: .black))
                    .frame(width: 34, height: 34)
                    .softPunchCard(
                        fill: categoryFill(milestone.category),
                        radius: 12
                    )

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(milestone.category.title)
                            .font(.system(
                                size: 10,
                                weight: .black,
                                design: .rounded
                            ))
                        Spacer()
                        Text(formattedDate(milestone.date))
                            .font(.system(
                                size: 9,
                                weight: .bold,
                                design: .monospaced
                            ))
                            .foregroundStyle(Color.punchInk.opacity(0.52))
                    }

                    Text(milestone.note)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(Color.punchInk.opacity(0.3))
                    .padding(.top, 3)
            }
            .padding(12)
            .softPunchCard(fill: .punchPaper, radius: 18)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .hoverLift()
    }

    private var editor: some View {
        VStack(spacing: 14) {
            editorHeader
            dateEditor
            categoryEditor
            noteEditor
            Spacer(minLength: 0)
            editorActions
        }
    }

    private var editorHeader: some View {
        HStack {
            Button(action: cancelEditing) {
                Image(systemName: "arrow.left")
                    .frame(width: 30, height: 30)
                    .softPunchCard(fill: .punchMint, radius: 12)
            }
            .buttonStyle(.plain)
            .hoverLift(.compact)

            Spacer()

            VStack(spacing: 2) {
                Text(editingMilestone == nil ? "记录一件大事" : "修改这件大事")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                Text("LIFE EVENTS")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(Color.punchInk.opacity(0.48))
            }

            Spacer()

            Color.clear.frame(width: 30, height: 30)
        }
    }

    private var dateEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            editorLabel("哪一天", systemImage: "calendar")
            DatePicker(
                "发生日期",
                selection: $draftDate,
                displayedComponents: .date
            )
            .datePickerStyle(.field)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .softPunchCard(fill: .punchPaper, radius: 18)
        .hoverLift()
    }

    private var categoryEditor: some View {
        VStack(alignment: .leading, spacing: 9) {
            editorLabel("属于哪一类", systemImage: "square.grid.2x2.fill")
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 8),
                    count: 3
                ),
                spacing: 8
            ) {
                ForEach(MilestoneCategory.allCases) { category in
                    Button {
                        draftCategory = category
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: category.systemImage)
                            Text(category.title)
                        }
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .softPunchCard(
                            fill: draftCategory == category
                                ? categoryFill(category) : .punchPaper,
                            radius: 12
                        )
                    }
                    .buttonStyle(.plain)
                    .hoverLift(.compact)
                }
            }
        }
    }

    private var noteEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            editorLabel("发生了什么", systemImage: "text.alignleft")
            TextEditor(text: $draftNote)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(height: 118)
                .softPunchCard(fill: .punchPaper, radius: 18)
            HStack {
                Text("写下值得记住的变化、决定或瞬间")
                Spacer()
                Text("\(draftNote.count)")
            }
            .font(.system(size: 9, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.punchInk.opacity(0.44))
        }
    }

    @ViewBuilder
    private var editorActions: some View {
        VStack(spacing: 9) {
            Button(action: saveDraft) {
                Label(
                    editingMilestone == nil ? "记下这件大事" : "保存修改",
                    systemImage: "checkmark"
                )
                .font(.system(size: 12, weight: .black, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.punchInk)
                .foregroundStyle(Color.punchCream)
                .clipShape(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .hoverLift()
            .disabled(cleanedDraftNote.isEmpty)
            .opacity(cleanedDraftNote.isEmpty ? 0.35 : 1)

            if editingMilestone != nil {
                Button(action: deleteDraft) {
                    Label("删除这件大事", systemImage: "trash.fill")
                        .font(.system(
                            size: 10,
                            weight: .black,
                            design: .rounded
                        ))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .softPunchCard(fill: .punchCoral, radius: 12)
                }
                .buttonStyle(.plain)
                .hoverLift(.compact)
            }
        }
    }

    private func editorLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(Color.punchInk.opacity(0.62))
    }

    private func categoryFill(_ category: MilestoneCategory) -> Color {
        switch category {
        case .work:
            .punchCoral
        case .life:
            .punchMint
        case .growth:
            .punchPaper
        case .relationship:
            .punchCoral.opacity(0.72)
        case .health:
            .punchMint.opacity(0.78)
        case .other:
            .punchPaper
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年 M月d日"
        return formatter.string(from: date)
    }

    private func beginCreating() {
        editingMilestone = nil
        isCreating = true
        draftDate = Date()
        draftCategory = selectedCategory ?? .life
        draftNote = ""
    }

    private func beginEditing(_ milestone: Milestone) {
        editingMilestone = milestone
        isCreating = false
        draftDate = milestone.date
        draftCategory = milestone.category
        draftNote = milestone.note
    }

    private func cancelEditing() {
        editingMilestone = nil
        isCreating = false
        draftNote = ""
    }

    private func saveDraft() {
        let saved: Bool
        if let editingMilestone {
            saved = milestones.update(
                id: editingMilestone.id,
                date: draftDate,
                note: draftNote,
                category: draftCategory
            )
        } else {
            saved = milestones.add(
                date: draftDate,
                note: draftNote,
                category: draftCategory
            )
        }

        if saved {
            cancelEditing()
        }
    }

    private func deleteDraft() {
        guard
            let editingMilestone,
            milestones.delete(id: editingMilestone.id)
        else {
            return
        }
        cancelEditing()
    }
}
