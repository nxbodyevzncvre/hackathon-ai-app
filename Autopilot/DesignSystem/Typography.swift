import SwiftUI

/// Named type roles from the design system. System text styles keep native
/// Dynamic Type scaling; weights and tracking match the spec.
///
/// The primary API is on `Text` (returns `Text`), which lets us apply the
/// spec's per-role tracking via `Text.kerning`. A generic `View` overload
/// covers places that hold richer content than plain text.
enum TypeRole {
    case screenTitle, sectionHeader, taskTitle, body, meta, chip

    var font: Font {
        switch self {
        case .screenTitle: .system(.largeTitle).weight(.semibold)
        case .sectionHeader: .system(.footnote).weight(.semibold)
        case .taskTitle: .system(.body).weight(.medium)
        case .body: .system(.body)
        case .meta: .system(.footnote)
        case .chip: .system(.caption).weight(.medium)
        }
    }

    var tracking: CGFloat {
        switch self {
        case .screenTitle: -0.6
        case .sectionHeader: 0.6
        case .taskTitle: -0.2
        case .body, .meta, .chip: 0
        }
    }

    var isUppercased: Bool { self == .sectionHeader }

    var defaultColor: Color {
        switch self {
        case .screenTitle, .taskTitle, .body: .text
        case .sectionHeader, .meta, .chip: .textSecondary
        }
    }
}

extension Text {
    /// Applies the role's font, tracking and color. Uppercase is the caller's
    /// concern (see `SectionHeader`) — `textCase` isn't a `Text`-chainable
    /// modifier, and returning `Text` keeps tracking chainable.
    func typeStyle(_ role: TypeRole, color: Color? = nil) -> Text {
        self
            .font(role.font)
            .tracking(role.tracking)
            .foregroundStyle(color ?? role.defaultColor)
    }
}

private struct TypeStyleModifier: ViewModifier {
    let role: TypeRole
    let color: Color?

    func body(content: Content) -> some View {
        Group {
            if role.isUppercased {
                content.textCase(.uppercase)
            } else {
                content
            }
        }
        .font(role.font)
        .foregroundStyle(color ?? role.defaultColor)
    }
}

extension View {
    /// Applies a named type role to arbitrary content (no kerning; use the
    /// `Text` overload when plain text needs the spec's tracking).
    func typeStyle(_ role: TypeRole, color: Color? = nil) -> some View {
        modifier(TypeStyleModifier(role: role, color: color))
    }
}
