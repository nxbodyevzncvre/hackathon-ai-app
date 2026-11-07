import SwiftUI

/// Inbox: all actions, grouped with unsorted first, category chip filter,
/// weekly strip, weekly numbers. Pushes into TaskDetailView on tap.
struct InboxView: View {
    var onCapture: () -> Void

    @Environment(ActionRepository.self) private var repository
    @State private var viewModel: InboxViewModel?
    @State private var path: [UUID] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.s28) {
                    Text("Inbox")
                        .typeStyle(.screenTitle)
                    if let viewModel {
                        content(viewModel)
                    } else {
                        EmptyState(
                            icon: "tray",
                            title: "Inbox is ready",
                            message: "Captured actions will appear here."
                        )
                    }
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
            .task {
                if viewModel == nil {
                    viewModel = InboxViewModel(repository: repository)
                    viewModel?.reload()
                }
            }
        }
        .accessibilityIdentifier("screen-inbox")
    }

    @ViewBuilder
    private func content(_ viewModel: InboxViewModel) -> some View {
        if !viewModel.hasActions {
            EmptyState(
                icon: "tray",
                title: "No actions yet",
                message: "Everything you capture lands here, unsorted first, until it is scheduled or done.",
                item: .init(title: "Capture something", perform: onCapture)
            )
        } else {
            weeklyStrip(viewModel.weekly)
            SegmentedFilter(
                options: InboxViewModel.categoryTitles,
                selection: Binding(
                    get: { viewModel.categoryIndex },
                    set: { viewModel.selectCategory($0) }
                )
            )
            sectionsList(viewModel)
        }
    }

    private func weeklyStrip(_ summary: WeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.s12) {
            SectionHeader(title: "This week")
            HStack(spacing: Theme.Space.s8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.success)
                Text("\(summary.completedCount) done this week")
                    .typeStyle(.meta)
                Spacer()
                Text("\(summary.openCount) open")
                    .typeStyle(.meta)
            }
            .padding(Theme.Space.s16)
            .surfaceCard()
        }
    }

    @ViewBuilder
    private func sectionsList(_ viewModel: InboxViewModel) -> some View {
        let display = viewModel.filteredSections
        if display.isEmpty {
            EmptyState(
                icon: "line.3.horizontal.decrease",
                title: "Nothing in this category",
                message: "Switch to All or capture something new."
            )
        } else {
            VStack(alignment: .leading, spacing: Theme.Space.s24) {
                ForEach(display) { section in
                    VStack(alignment: .leading, spacing: Theme.Space.s8) {
                        SectionHeader(title: section.title)
                        ForEach(section.actions) { action in
                            row(action, viewModel: viewModel)
                        }
                    }
                }
            }
        }
    }

    private func row(_ action: Action, viewModel: InboxViewModel) -> some View {
        Button {
            path.append(action.id)
        } label: {
            TaskRow(action: action) { id in
                viewModel.toggleDone(id)
            }
        }
        .buttonStyle(PressableStyle())
        .accessibilityHint("Opens details for \(action.title)")
    }
}
