import SwiftUI

@main
struct TapCounterWatchApp: App {
    init() {
        _ = WatchSessionManager.shared
    }

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
    }
}
