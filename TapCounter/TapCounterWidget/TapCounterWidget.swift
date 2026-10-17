import ActivityKit
import SwiftUI
import WidgetKit

@main
struct TapCounterWidgetBundle: WidgetBundle {
    var body: some Widget {
        TapCounterLiveActivity()
    }
}

struct TapCounterLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TapCounterActivityAttributes.self) { context in
            // Lock Screen and Home Screen Live Activity Banner
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color(UIColor.secondarySystemBackground))
                .widgetURL(URL(string: "tapcounter://session/\(context.attributes.sessionId)"))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: modeIcon(context.attributes.mode))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(modeColor(context.attributes.mode))
                        Text(context.attributes.sessionName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                    }
                    .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.attributes.mode == "Target", let target = context.attributes.targetCount {
                        Text("\(context.state.count)/\(target)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.trailing, 8)
                    } else if context.attributes.mode == "Timer", let duration = context.attributes.timerDuration {
                        let remaining = max(duration - context.state.elapsedTime, 0)
                        let mins = Int(remaining) / 60
                        let secs = Int(remaining) % 60
                        Text(String(format: "%02d:%02d", mins, secs))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .foregroundColor(.orange)
                            .padding(.trailing, 8)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("\(context.state.count)")
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.attributes.mode == "Target", let target = context.attributes.targetCount, target > 0 {
                        ProgressView(value: min(Double(context.state.count) / Double(target), 1.0))
                            .tint(.green)
                            .padding(.horizontal, 16)
                    } else if context.attributes.mode == "Timer", let duration = context.attributes.timerDuration, duration > 0 {
                        ProgressView(value: min(context.state.elapsedTime / duration, 1.0))
                            .tint(.orange)
                            .padding(.horizontal, 16)
                    }
                }
            } compactLeading: {
                // 1. Simple count: left app icon
                // 2. Target count: left app icon
                // 3. Timer count: left app icon + count
                if context.attributes.mode == "Timer" {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.orange)
                        Text("\(context.state.count)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .padding(.leading, 4)
                } else if context.attributes.mode == "Target" {
                    Image(systemName: "target")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.green)
                        .padding(.leading, 4)
                } else {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.blue)
                        .padding(.leading, 4)
                }
            } compactTrailing: {
                // 1. Simple count: right tap count
                // 2. Target count: right tap count/target count
                // 3. Timer count: right timer
                if context.attributes.mode == "Timer", let duration = context.attributes.timerDuration {
                    let remaining = max(duration - context.state.elapsedTime, 0)
                    let mins = Int(remaining) / 60
                    let secs = Int(remaining) % 60
                    Text(String(format: "%02d:%02d", mins, secs))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                        .padding(.trailing, 4)
                } else if context.attributes.mode == "Target", let target = context.attributes.targetCount {
                    Text("\(context.state.count)/\(target)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.trailing, 4)
                } else {
                    Text("\(context.state.count)")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.trailing, 4)
                }
            } minimal: {
                Text("\(context.state.count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(modeColor(context.attributes.mode))
            }
            .widgetURL(URL(string: "tapcounter://session/\(context.attributes.sessionId)"))
        }
    }

    private func modeIcon(_ mode: String) -> String {
        switch mode {
        case "Target": return "target"
        case "Timer": return "timer"
        default: return "hand.tap.fill"
        }
    }

    private func modeColor(_ mode: String) -> Color {
        switch mode {
        case "Target": return .green
        case "Timer": return .orange
        default: return .blue
        }
    }
}

// MARK: - Lock Screen & Banner View
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<TapCounterActivityAttributes>

    var accentColor: Color {
        switch context.attributes.mode {
        case "Target": return .green
        case "Timer": return .orange
        default: return .blue
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: modeIcon(context.attributes.mode))
                    .font(.system(size: 22))
                    .foregroundColor(accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(context.attributes.sessionName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                if context.attributes.mode == "Target", let target = context.attributes.targetCount {
                    Text("Target: \(target) taps")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if context.attributes.mode == "Timer", let duration = context.attributes.timerDuration {
                    let remaining = max(duration - context.state.elapsedTime, 0)
                    let mins = Int(remaining) / 60
                    let secs = Int(remaining) % 60
                    Text("Remaining: \(String(format: "%02d:%02d", mins, secs))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                } else {
                    Text("Tap Counting Session")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Big Tap Count Number
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(context.state.count)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("taps")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(UIColor.secondarySystemBackground))
    }

    private func modeIcon(_ mode: String) -> String {
        switch mode {
        case "Target": return "target"
        case "Timer": return "timer"
        default: return "hand.tap.fill"
        }
    }
}
