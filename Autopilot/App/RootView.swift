import SwiftUI

enum AppTab: Hashable {
    case today, inbox, settings
}

struct RootView: View {
    @State private var tab: AppTab
    @State private var isCapturePresented: Bool

    init() {
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
            initialValue: args.contains("-autopilot-show-capture")
        )
    }

    var body: some View {
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
        .overlay(alignment: .bottomTrailing) { captureButton }
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
}
