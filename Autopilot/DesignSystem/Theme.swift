import SwiftUI
import UIKit

// Semantic color tokens. This is the only place light and dark values are
// defined; views reference tokens and never hardcode colors.

private func uiHex(_ hex: UInt32) -> UIColor {
    UIColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
    )
}

private func themeColor(light: UInt32, dark: UInt32) -> Color {
    Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? uiHex(dark) : uiHex(light)
    })
}

extension Color {
    static let bg = themeColor(light: 0xFFFFFF, dark: 0x111110)
    static let surface = themeColor(light: 0xF7F7F5, dark: 0x191917)
    static let surfaceField = themeColor(light: 0xFFFFFF, dark: 0x222220)
    static let text = themeColor(light: 0x191917, dark: 0xF3F3EF)
    static let textSecondary = themeColor(light: 0x6C6C66, dark: 0xA3A39B)
    static let textTertiary = themeColor(light: 0x9A9A93, dark: 0x75756E)
    static let border = themeColor(light: 0xE6E6E1, dark: 0x2C2C29)
    static let accent = themeColor(light: 0x191917, dark: 0xF3F3EF)
    static let onAccent = themeColor(light: 0xFFFFFF, dark: 0x111110)
    static let danger = themeColor(light: 0xB0432E, dark: 0xE07A63)
    static let success = themeColor(light: 0x3F6B4E, dark: 0x7FB894)
    static let warning = themeColor(light: 0x9A6B1F, dark: 0xD6A85C)
}

enum Theme {
    enum Space {
        static let s4: CGFloat = 4
        static let s8: CGFloat = 8
        static let s12: CGFloat = 12
        static let s16: CGFloat = 16
        static let s14: CGFloat = 14
        static let s20: CGFloat = 20
        static let s24: CGFloat = 24
        static let s28: CGFloat = 28
        static let s32: CGFloat = 32
        static let s48: CGFloat = 48
        static let s88: CGFloat = 88
    }

    enum Radius {
        static let chip: CGFloat = 10
        static let card: CGFloat = 14
        static let sheet: CGFloat = 20
    }

    enum Screen {
        static let hPadding: CGFloat = 20
    }
}

extension Animation {
    /// 0.18s easeOut, for state changes.
    static let themeEaseOut: Animation = Animation.easeOut(duration: 0.18)
    /// Confirm-sheet presentation spring.
    static let confirmSpring: Animation = Animation.spring(
        response: 0.32,
        dampingFraction: 0.86
    )
}

extension View {
    /// Card look: surface fill + 1pt border stroke, no shadow.
    func surfaceCard(
        radius: CGFloat = Theme.Radius.card,
        fill: Color = .surface
    ) -> some View {
        self
            .background(fill, in: RoundedRectangle.cornerContinuous(radius))
            .overlay(
                RoundedRectangle.cornerContinuous(radius)
                    .strokeBorder(Color.border, lineWidth: 1)
            )
    }
}

extension RoundedRectangle {
    static func cornerContinuous(_ radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }
}
