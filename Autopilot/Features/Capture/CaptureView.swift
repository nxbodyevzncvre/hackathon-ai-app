import SwiftUI

/// Capture sheet (text capture in this build). Parsing connects with the
/// extraction milestone; until then the sheet is honest about it and nothing
/// typed here is stored.
struct CaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.s24) {
                    TextField(
                        "What is happening?",
                        text: $text,
                        axis: .vertical
                    )
                    .lineLimit(4...10)
                    .padding(Theme.Space.s12)
                    .surfaceCard(fill: .surfaceField)
                    .font(.body)
                    .accessibilityLabel("What is happening")

                    InlineNotice(
                        message: "Parsing is not connected in this build yet. Typed text stays inside this sheet and is discarded when you close it.",
                        systemImage: "info.circle"
                    )

                    PrimaryButton(
                        title: "Parse",
                        systemImage: "wand.and.stars",
                        isEnabled: false,
                        action: {}
                    )
                    .accessibilityHint("Parsing arrives in an upcoming build")
                }
                .padding(.horizontal, Theme.Screen.hPadding)
                .padding(.top, Theme.Space.s24)
                .padding(.bottom, Theme.Space.s32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Color.bg)
            .navigationTitle("Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .typeStyle(.taskTitle)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(Theme.Radius.sheet)
        .presentationDragIndicator(.visible)
    }
}
