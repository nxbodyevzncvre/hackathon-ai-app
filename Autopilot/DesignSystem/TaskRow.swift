import SwiftUI

/// TaskRow renders a domain `Action` value type. Persistence comes in M1;
/// this row is the shared visual unit for Today and Inbox lists.

struct TaskRow: View {
    let action: Action
    var onToggle: ((UUID) -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Space.s12) {
            toggle
            VStack(alignment: .leading, spacing: Theme.Space.s8) {
                Text(action.title)
                    .typeStyle(.taskTitle, color: action.isDone ? .textSecondary : .text)
                    .strikethrough(action.isDone, color: .textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                metaRow
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, Theme.Space.s14)
        .padding(.horizontal, Theme.Space.s16)
        .surfaceCard()
        .contentShape(RoundedRectangle.cornerContinuous(Theme.Radius.card))
    }

    /// 44pt tappable checkbox with icon-based done state.
    private var toggle: some View {
        Button {
            onToggle?(action.id)
        } label: {
            Image(systemName: action.isDone ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(action.isDone ? Color.success : Color.textTertiary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(action.isDone ? "Mark not done" : "Mark done")
        .accessibilityHint("For \(action.title)")
    }

    @ViewBuilder private var metaRow: some View {
        HStack(spacing: Theme.Space.s8) {
            if let symbol = action.priority.symbolName {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(action.priority == .high ? Color.danger : Color.textSecondary)
                Text(action.priority.displayName)
                    .typeStyle(.chip, color: .textSecondary)
            }
            Text(action.categoryKind.displayName)
                .typeStyle(.chip)
            if let due = action.due {
                Image(systemName: "calendar")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                Text(due.displayLabel)
                    .typeStyle(.chip)
            }
            if let estimate = action.estimateLabel {
                Text(estimate)
                    .typeStyle(.chip)
            }
        }
        .foregroundStyle(Color.textSecondary)
    }
}
