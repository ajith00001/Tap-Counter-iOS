import SwiftUI

@main
struct TapCounterApp: App {
    init() {
        _ = PhoneWatchSyncManager.shared
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
