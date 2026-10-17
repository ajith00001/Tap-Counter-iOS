import SwiftUI
import WatchKit

struct WatchCounterView: View {
    @ObservedObject var manager = WatchSessionManager.shared
    @State private var crownValue: Double = 0
    @State private var lastCrownInt: Int = 0
    @State private var isTapped = false

    var session: WatchTapSession? {
        manager.currentSession
    }

    var accentColor: Color {
        switch session?.mode {
        case "Target": return .green
        case "Timer": return .orange
        default: return .blue
        }
    }

    var body: some View {
        ZStack {
            // Background tap-to-count zone
            Color.black
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    triggerTapAnimation()
                    manager.tap()
                }

            VStack(spacing: 4) {
                // Top status bar
                HStack(spacing: 4) {
                    Circle()
                        .fill(manager.isReachableWithPhone ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                    Text(session?.name ?? "Quick Count")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Center Count & Progress
                ZStack {
                    if let progress = session?.progress {
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                            .frame(width: 104, height: 104)

                        Circle()
                            .trim(from: 0, to: CGFloat(progress))
                            .stroke(accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 104, height: 104)
                            .animation(.spring(response: 0.3), value: progress)
                    }

                    VStack(spacing: 0) {
                        Text("\(session?.count ?? 0)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .scaleEffect(isTapped ? 0.94 : 1.0)
                            .animation(.easeOut(duration: 0.08), value: isTapped)

                        if session?.mode == "Target", let target = session?.targetCount {
                            Text("/ \(target)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                        } else if session?.mode == "Timer", let remaining = session?.formattedRemainingTime {
                            Text(remaining)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(accentColor)
                        }
                    }
                }

                Spacer()

                // Bottom utility controls
                HStack(spacing: 12) {
                    Button {
                        manager.subtract()
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.15), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        manager.reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.15), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        manager.endSession()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.red)
                            .frame(width: 34, height: 34)
                            .background(Color.red.opacity(0.15), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 2)
            }
            .padding(.horizontal, 6)
        }
        .focusable()
        .digitalCrownRotation($crownValue, from: -1000, through: 1000, by: 1.0, sensitivity: .medium, isContinuous: true, isHapticFeedbackEnabled: true)
        .onChange(of: crownValue) { oldValue, newValue in
            let newInt = Int(newValue)
            if newInt > lastCrownInt {
                manager.tap()
                lastCrownInt = newInt
            } else if newInt < lastCrownInt {
                manager.subtract()
                lastCrownInt = newInt
            }
        }
    }

    private func triggerTapAnimation() {
        withAnimation(.easeOut(duration: 0.08)) {
            isTapped = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            isTapped = false
        }
    }
}
