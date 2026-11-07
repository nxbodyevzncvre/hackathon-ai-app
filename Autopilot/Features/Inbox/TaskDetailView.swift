import SwiftUI

/// Task detail: view and edit one action; edits write through to the store
/// immediately (same contract as Settings). Delete asks for confirmation.
struct TaskDetailView: View {
    let actionID: UUID

    @Environment(ActionRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Action?
    @State private var statusBeforeDone: ActionStatus = .inbox
    @State private var showsDeleteConfirmation = false

    private var calendar = Calendar.current

    init(actionID: UUID) {
        self.actionID = actionID
    }

    var body: some View {
        Group {
            if let draft {
                content(draft)
            } else {
                Color.bg
            }
        }
        .background(Color.bg)
        .task {
            if draft == nil {
                draft = try? repository.action(id: actionID)
                statusBeforeDone = draft?.status ?? .inbox
            }
        }
        .onChange(of: draft) { _, newValue in
            if let newValue {
                try? repository.update(newValue)
            }
        }
        .confirmationDialog(
            "Delete this action?",
            isPresented: $showsDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                try? repository.delete(id: actionID)
                dismiss()
            }
        } message: {
            Text("This cannot be undone.")
        }
    }

    private func content(_ draft: Action) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.s28) {
                SectionHeader(title: "Action")
                VStack(spacing: 0) {
                    titleRow
                    Divider().overlay(Color.border)
                    doneRow
                }
                .surfaceCard()

                SectionHeader(title: "Classification")
                VStack(spacing: 0) {
                    kindRow
                    Divider().overlay(Color.border)
                    categoryRow
                    Divider().overlay(Color.border)
                    priorityRow
                }
                .surfaceCard()

                SectionHeader(title: "When")
                VStack(spacing: 0) {
                    dueRow
                    if draft.due != nil {
                        Divider().overlay(Color.border)
                        timeRow
                    }
                }
                .surfaceCard()

                SectionHeader(title: "Details")
                VStack(spacing: 0) {
                    estimateRow
                    Divider().overlay(Color.border)
                    reminderRow
                    Divider().overlay(Color.border)
                    notesRow
                }
                .surfaceCard()

                SecondaryButton(title: "Delete", systemImage: "trash", action: {
                    showsDeleteConfirmation = true
                })
                .tint(Color.danger)
            }
            .padding(.horizontal, Theme.Screen.hPadding)
            .padding(.top, Theme.Space.s24)
            .padding(.bottom, Theme.Space.s32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .navigationTitle(draft.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Bindings into the draft

    private func bind<T>(_ keyPath: WritableKeyPath<Action, T>) -> Binding<T> {
        Binding(
            get: { draft?[keyPath: keyPath] ?? fallbackValue(keyPath) },
            set: { draft?[keyPath: keyPath] = $0 }
        )
    }

    private func fallbackValue<T>(_ keyPath: WritableKeyPath<Action, T>) -> T {
        // Never reached in practice: rows render only when a draft exists.
        Action(title: "")[keyPath: keyPath]
    }

    private var titleRow: some View {
        TextField("Title", text: bind(\.title))
            .typeStyle(.taskTitle)
            .padding(Theme.Space.s16)
            .frame(minHeight: 52)
    }

    private var doneRow: some View {
        Button {
            guard var action = draft else { return }
            if action.status == .done {
                action.status = statusBeforeDone
                action.completedAt = nil
            } else {
                statusBeforeDone = action.status
                action.status = .done
                action.completedAt = .now
            }
            draft = action
        } label: {
            Label(
                (draft?.status == .done) ? "Undo done" : "Mark as done",
                systemImage: (draft?.status == .done) ? "arrow.uturn.backward" : "checkmark"
            )
            .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(PressableStyle())
    }

    private var kindRow: some View {
        HStack {
            Text("Kind").typeStyle(.taskTitle)
            Spacer()
            Menu(draft?.kind.displayName ?? "Task") {
                ForEach(ActionKind.allCases, id: \.self) { kind in
                    Button(kind.displayName) { draft?.kind = kind }
                }
            }
            .typeStyle(.meta)
        }
        .padding(Theme.Space.s16)
    }

    private var categoryRow: some View {
        HStack {
            Text("Category").typeStyle(.taskTitle)
            Spacer()
            Menu(ActionCategory.normalized(draft?.category ?? "other").displayName) {
                ForEach(ActionCategory.fixed, id: \.self) { category in
                    Button(category.displayName) { draft?.category = category.rawValue }
                }
            }
            .typeStyle(.meta)
        }
        .padding(Theme.Space.s16)
    }

    private var priorityRow: some View {
        HStack {
            Text("Priority").typeStyle(.taskTitle)
            Spacer()
            Picker("Priority", selection: bind(\.priority)) {
                ForEach(Priority.allCases, id: \.self) { priority in
                    Text(priority.displayName).tag(priority)
                }
            }
            .pickerStyle(.segmented)
            .fixedSize()
        }
        .padding(Theme.Space.s16)
    }

    private var dueRow: some View {
        HStack {
            Toggle("Has due date", isOn: Binding(
                get: { draft?.due != nil },
                set: { hasDate in
                    if hasDate {
                        let day = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now)) ?? .now
                        draft?.due = DueDate.day(day)
                    } else {
                        draft?.due = nil
                    }
                }
            ))
            .typeStyle(.taskTitle)
            if draft?.due != nil {
                Spacer()
                DatePicker(
                    "",
                    selection: Binding(
                        get: { draft?.due?.date ?? .now },
                        set: { newDate in
                            guard var due = draft?.due else { return }
                            let followingTime = due.time
                            due.date = calendar.startOfDay(for: newDate)
                            due.time = followingTime
                            if due.precision == .unknown { due.precision = .day }
                            draft?.due = due
                        }
                    ),
                    displayedComponents: .date
                )
                .labelsHidden()
                .fixedSize()
            }
        }
        .padding(Theme.Space.s16)
    }

    private var timeRow: some View {
        HStack {
            Toggle("Specific time", isOn: Binding(
                get: { draft?.due?.time != nil },
                set: { hasTime in
                    if hasTime {
                        draft?.due?.time = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: draft?.due?.date ?? .now) ?? .now
                        draft?.due?.precision = .time
                    } else {
                        draft?.due?.time = nil
                        draft?.due?.precision = .day
                    }
                }
            ))
            .typeStyle(.taskTitle)
            if let time = draft?.due?.time {
                Spacer()
                DatePicker(
                    "",
                    selection: Binding(
                        get: { time },
                        set: { newTime in
                            guard var due = draft?.due else { return }
                            let day = calendar.startOfDay(for: due.date)
                            let minutes = calendar.dateComponents([.hour, .minute], from: newTime)
                            due.time = calendar.date(
                                byAdding: .minute,
                                value: (minutes.hour ?? 0) * 60 + (minutes.minute ?? 0),
                                to: day
                            ) ?? newTime
                            draft?.due = due
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .fixedSize()
            }
        }
        .padding(Theme.Space.s16)
    }

    private var estimateRow: some View {
        HStack {
            Text("Estimate").typeStyle(.taskTitle)
            Spacer()
            Stepper(
                draft?.estimateLabel ?? "No estimate",
                value: Binding(
                    get: { draft?.estimateMinutes ?? 15 },
                    set: { draft?.estimateMinutes = min(max($0, 5), 480) }
                ),
                in: 5...480,
                step: 5
            )
            .fixedSize()
        }
        .padding(Theme.Space.s16)
    }

    private var reminderRow: some View {
        HStack {
            Text("Reminders").typeStyle(.taskTitle)
            Spacer()
            Text(reminderLabels.joined(separator: " · "))
                .typeStyle(.meta)
                .multilineTextAlignment(.trailing)
        }
        .padding(Theme.Space.s16)
    }

    private var reminderLabels: [String] {
        guard draft?.reminder.isEnabled == true, !draft!.reminder.offsets.isEmpty else {
            return ["Off"]
        }
        let hours = draft!.reminder.offsets.map { abs($0) / 3600 }.sorted { $0 > $1 }
        return hours.map { label(forHours: $0) }
    }

    private func label(forHours hours: Double) -> String {
        if hours >= 24 { return "\(Int(hours / 24))d before" }
        return "\(Int(hours))h before"
    }

    private var notesRow: some View {
        TextField("Notes", text: bind(\.notes), axis: .vertical)
            .lineLimit(2...6)
            .font(.body)
            .padding(Theme.Space.s16)
            .accessibilityLabel("Notes")
    }
}
