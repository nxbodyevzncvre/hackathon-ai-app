import SwiftUI

/// Owns the app's services. Later milestones grow this from settings-only
/// to extraction/plan/notification wiring; screens keep reading it via
/// `@Environment(AppEnvironment.self)`.
@MainActor
@Observable
final class AppEnvironment {
    let settings: SettingsStore

    init(settings: SettingsStore = SettingsStore()) {
        self.settings = settings
    }
}
