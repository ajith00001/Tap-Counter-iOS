import SwiftUI

struct WatchHomeView: View {
    @ObservedObject var manager = WatchSessionManager.shared

    var body: some View {
        NavigationStack {
            if manager.currentSession != nil {
                WatchCounterView()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        // Quick Start Big Button
                        Button {
                            manager.startQuickSession(mode: "Simple")
                        } label: {
                            HStack {
                                Image(systemName: "hand.tap.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Start Counting")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Free Tap Count")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .tint(.blue.opacity(0.2))

                        // Target 108 (Mantra / Japa / Goal)
                        Button {
                            manager.startQuickSession(mode: "Target", target: 108)
                        } label: {
                            HStack {
                                Image(systemName: "target")
                                    .font(.system(size: 16))
                                    .foregroundColor(.green)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Target 108")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Goal tracking")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .tint(.green.opacity(0.15))

                        // Timer 5 Minutes
                        Button {
                            manager.startQuickSession(mode: "Timer", duration: 300)
                        } label: {
                            HStack {
                                Image(systemName: "timer")
                                    .font(.system(size: 16))
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("5 Min Timer")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Timed session")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .tint(.orange.opacity(0.15))
                    }
                    .padding(.horizontal, 4)
                }
                .navigationTitle("Tap Counter")
            }
        }
        .onAppear {
            manager.requestStateFromPhone()
        }
    }
}
