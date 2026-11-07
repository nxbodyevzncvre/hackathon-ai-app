import SwiftUI

/// Today: plan for the day, overdue section, briefing card. They land in M4;
/// M0 stays honest with the primary-journey empty state.
struct TodayView: View {
    var onCapture: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.s28) {
                Text("Today")
                    .typeStyle(.screenTitle)
                EmptyState(
                    icon: "sun.max",
                    title: "Nothing on the plan",
                    message: "Tell AUTOPILOT what is happening and it turns your words into scheduled actions.",
                    item: .init(
                        title: "Tell AUTOPILOT what is happening",
                        perform: onCapture
                    )
                )
            }
            .padding(.horizontal, Theme.Screen.hPadding)
            .padding(.top, Theme.Space.s24)
            .padding(.bottom, Theme.Space.s32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.bg)
        .accessibilityIdentifier("screen-today")
    }
}
