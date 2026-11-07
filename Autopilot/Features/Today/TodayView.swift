import SwiftUI

/// Today: overdue + due-today feed. The capacity-aware plan and briefing
/// card arrive in M4; until then the screen stays honest about that.
struct TodayView: View {
    var onCapture: () -> Void

    @Environment(ActionRepository.self) private var repository
    @State private var actions: [Action] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.s28) {
                    Text("Today")
                        .typeStyle(.screenTitle)
                    content
                }
                .padding(.horizontal, Theme.Screen.hPadding)
                .padding(.top, Theme.Space.s24)
                .padding(.bottom, Theme.Space.s32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Color.bg)
            .navigationDestination(for: UUID.self) { id in
                TaskDetailView(actionID: id)
            }
            .task { reload() }
            .onAppear { reload() }
        }
        .accessibilityIdentifier("screen-today")
    }

    @ViewBuilder
    private var content: some View {
        let calendar = Calendar.current
        let today = TodayScreen.sections(for: actions, now: .now, calendar: calendar)

        if today.openCount == 0 {
            EmptyState(
                icon: "sun.max",
                title: "Nothing on the plan",
                message: "Tell AUTOPILOT what is happening and it turns your words into scheduled actions.",
                item: .init(
                    title: "Tell AUTOPILOT what is happening",
                    perform: onCapture
                )
            )
        } else {
            if today.overdue.isEmpty == false {
                VStack(alignment: .leading, spacing: Theme.Space.s8) {
                    SectionHeader(title: "Overdue")
                    ForEach(today.overdue) { action in
                        row(action)
                    }
                }
            }
            if today.dueToday.isEmpty == false {
                VStack(alignment: .leading, spacing: Theme.Space.s8) {
                    SectionHeader(title: "Due today")
                    ForEach(today.dueToday) { action in
                        row(action)
                    }
                }
            }
            if today.overdue.isEmpty && today.dueToday.isEmpty {
                InlineNotice(
                    message: "\(today.openCount) open action\(today.openCount == 1 ? "" : "s") waits in Inbox. Planning of today's capacity arrives with the planning milestone.",
                    systemImage: "calendar.badge.clock",
                    tone: .textSecondary
                )
            }
        }
    }

    private func row(_ action: Action) -> some View {
        NavigationLink(value: action.id) {
            TaskRow(action: action)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens details for \(action.title)")
    }

    private func reload() {
        actions = (try? repository.actions()) ?? []
    }
}
