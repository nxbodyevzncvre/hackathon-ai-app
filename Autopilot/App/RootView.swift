import SwiftUI

enum AppTab: Hashable {
    case today, inbox, settings
}

struct RootView: View {
    @Environment(AppEnvironment.self) private var environment

    @State private var tab: AppTab
    @State private var isCapturePresented: Bool
    /// Re-injected after init so mocks/fixtures can differ per launch args later.
    private let showCaptureByDefault: Bool

    init(showCaptureByDefault: Bool = false) {
        self.showCaptureByDefault = showCaptureByDefault
        // Screenshot verification hooks: `-autopilot-tab-<name>` picks the tab,
        // `-autopilot-show-capture` opens the capture sheet at launch.
        let args = ProcessInfo.processInfo.arguments
        let initial: AppTab
        if args.contains("-autopilot-tab-inbox") {
            initial = .inbox
        } else if args.contains("-autopilot-tab-settings") {
            initial = .settings
        } else {
            initial = .today
        }
        _tab = State(initialValue: initial)
        _isCapturePresented = State(
            initialValue: showCaptureByDefault || args.contains("-autopilot-show-capture")
        )
    }

    var body: some View {
        if let repository = environment.repository {
            tabs
                .environment(repository)
        } else {
            storageUnavailableView
        }
    }

    private var tabs: some View {
        TabView(selection: $tab) {
            TodayView(onCapture: openCapture)
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(AppTab.today)

            InboxView(onCapture: openCapture)
                .tabItem { Label("Inbox", systemImage: "tray") }
                .tag(AppTab.inbox)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .tint(Color.text)
        .overlay(alignment: .bottomTrailing) {
            if !isCapturePresented { captureButton }
        }
        .sheet(isPresented: $isCapturePresented) { CaptureView() }
    }

    private func openCapture() { isCapturePresented = true }

    private var captureButton: some View {
        Button(action: openCapture) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color.onAccent)
                .frame(width: 60, height: 60)
                .background(Color.accent, in: Circle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("Capture")
        .accessibilityIdentifier("capture-button")
        .padding(.trailing, Theme.Space.s20)
        .padding(.bottom, Theme.Space.s88)
    }

    /// Honest degradation instead of a crash when SwiftData cannot start.
    private var storageUnavailableView: some View {
        VStack {
            EmptyState(
                icon: "externaldrive.badge.exclamationmark",
                title: "Local storage unavailable",
                message: "The database could not be opened on this device, so AUTOPILOT cannot store actions. Nothing was lost on purpose — the app shows this screen instead of risking your data."
            )
            .padding(.horizontal, Theme.Screen.hPadding)
        }
        .background(Color.bg)
    }
}
