import SwiftUI

/// Shared pressed feedback for tappable blocks: tiny scale, 0.18s easeOut.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.themeEaseOut, value: configuration.isPressed)
    }
}

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Space.s8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .typeStyle(.taskTitle, color: .onAccent)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color.accent, in: RoundedRectangle.cornerContinuous(Theme.Radius.card))
            .opacity(isEnabled ? 1 : 0.45)
            .contentShape(RoundedRectangle.cornerContinuous(Theme.Radius.card))
        }
        .buttonStyle(PressableStyle())
        .disabled(!isEnabled)
        .accessibilityIdentifier("primary-button-\(title)")
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Space.s8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .medium))
                }
                Text(title)
                    .typeStyle(.taskTitle)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .surfaceCard(fill: .surfaceField)
            .contentShape(RoundedRectangle.cornerContinuous(Theme.Radius.card))
        }
        .buttonStyle(PressableStyle())
    }
}

/// Small pill label. Presentational only; `SegmentedFilter` owns selection.
struct Chip: View {
    let title: String
    var systemImage: String? = nil
    var isSelected = false
    var tone: Color = .textSecondary

    var body: some View {
        HStack(spacing: Theme.Space.s4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.onAccent : tone)
            }
            Text(title)
                .typeStyle(.chip, color: isSelected ? .onAccent : tone)
                .lineLimit(1)
        }
        .padding(.horizontal, Theme.Space.s12)
        .padding(.vertical, Theme.Space.s4)
        .background(
            isSelected ? Color.accent : Color.surface,
            in: RoundedRectangle.cornerContinuous(Theme.Radius.chip)
        )
        .overlay(
            RoundedRectangle.cornerContinuous(Theme.Radius.chip)
                .strokeBorder(isSelected ? Color.clear : Color.border, lineWidth: 1)
        )
        .fixedSize()
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .typeStyle(.sectionHeader)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Category / segment picker inside a screen. Selection is index-based;
/// callers map indices to domain values.
struct SegmentedFilter: View {
    let options: [String]
    @Binding var selection: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Space.s8) {
                ForEach(options.indices, id: \.self) { index in
                    Button {
                        withAnimation(.themeEaseOut) { selection = index }
                    } label: {
                        Chip(title: options[index], isSelected: selection == index)
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityAddTraits(selection == index ? [.isSelected] : [])
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .accessibilityLabel("Filter")
    }
}
