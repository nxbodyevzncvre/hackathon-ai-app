import SwiftUI

// Overlay components: empty states, inline notices, toasts, skeletons.

struct EmptyState: View {
    struct Action {
        let title: String
        let perform: () -> Void
    }

    let icon: String
    let title: String
    let message: String
    var item: Action? = nil

    var body: some View {
        VStack(spacing: Theme.Space.s16) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(Color.textTertiary)
            VStack(spacing: Theme.Space.s8) {
                Text(title)
                    .typeStyle(.taskTitle)
                    .multilineTextAlignment(.center)
                Text(message)
                    .typeStyle(.body, color: .textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let item {
                PrimaryButton(title: item.title, action: item.perform)
            }
        }
        .padding(.vertical, Theme.Space.s48)
        .padding(.horizontal, Theme.Space.s32)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// Non-fatal inline message: warning icon + text, never color-only.
struct InlineNotice: View {
    let message: String
    var systemImage: String = "info.circle"
    var tone: Color = .warning

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Space.s8) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tone)
            Text(message)
                .typeStyle(.meta)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Space.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceCard()
    }
}

/// Bottom toast with optional underline action (e.g. Undo). Presentation
/// logic lands with M2 capture; this is the visual component.
struct Toast: View {
    let message: String
    var systemImage: String = "checkmark.circle.fill"
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Theme.Space.s8) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.success)
            Text(message)
                .typeStyle(.meta)
                .lineLimit(2)
            Spacer(minLength: Theme.Space.s4)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .typeStyle(.taskTitle, color: .text)
            }
        }
        .padding(.horizontal, Theme.Space.s16)
        .padding(.vertical, Theme.Space.s12)
        .surfaceCard(radius: Theme.Radius.sheet, fill: .surfaceField)
    }
}

/// Loading placeholder row. Static by default; shimmer lands with M2 usage.
struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: Theme.Space.s12) {
            RoundedRectangle.cornerContinuous(Theme.Radius.chip)
                .fill(Color.border)
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: Theme.Space.s8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.border)
                    .frame(height: 12)
                    .padding(.trailing, Theme.Space.s48)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.border)
                    .frame(height: 10)
                    .padding(.trailing, Theme.Space.s48 * 2)
            }
        }
        .padding(.vertical, Theme.Space.s16)
        .accessibilityLabel("Loading")
    }
}
