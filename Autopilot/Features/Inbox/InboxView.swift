import SwiftUI

/// Inbox: all actions, grouped, unsorted first, with a category chip filter
/// and a weekly progress strip. Both arrive with the data layer in M1.
struct InboxView: View {
    var onCapture: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.s28) {
                Text("Inbox")
                    .typeStyle(.screenTitle)
                EmptyState(
                    icon: "tray",
                    title: "No actions yet",
                    message: "Everything you capture lands here, unsorted first, until it is scheduled or done.",
                    item: .init(title: "Capture something", perform: onCapture)
                )
            }
            .padding(.horizontal, Theme.Screen.hPadding)
            .padding(.top, Theme.Space.s24)
            .padding(.bottom, Theme.Space.s32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.bg)
        .accessibilityIdentifier("screen-inbox")
    }
}
