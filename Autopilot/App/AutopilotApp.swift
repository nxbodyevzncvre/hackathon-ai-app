import SwiftUI

@main
struct AutopilotApp: App {
    /// App-wide object graph for the whole run; rebuilt with the process.
    @State private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .environment(environment.settings)
        }
    }
}
