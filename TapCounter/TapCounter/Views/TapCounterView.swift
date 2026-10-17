import SwiftUI

// MARK: - Tap Counter Screen
struct TapCounterView: View {
    @StateObject var viewModel: TapSessionViewModel
    @ObservedObject var session: TapSession    // Directly observe for @Published changes
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var isTapAreaActive = false
    @State private var showDeleteConfirmation = false

    init(viewModel: TapSessionViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._session = ObservedObject(wrappedValue: viewModel.session)
    }

    // Accent color based on mode
    var accentColor: Color {
        switch session.mode {
        case .simple: return .blue
        case .target: return .green
        case .timer: return .orange
        }
    }

    var body: some View {
        ZStack {
            // Background tap area (fills all space not covered by utility controls)
            tapZone

            // Foreground UI (non-interactive overlay)
            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                Spacer()

                // Central counter area
                counterCenter

                Spacer()

                // Bottom controls (utility buttons)
                bottomControls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }

            // Overlays
            if viewModel.showTargetReachedOverlay {
                overlayBackground
                OverlayNotificationView(
                    icon: "checkmark.circle.fill",
                    title: "Target Reached! 🎉",
                    subtitle: "You've hit your goal of \(session.targetCount ?? 0) taps!",
                    color: .green
                )
                .transition(.scale(scale: 0.8).combined(with: .opacity))
                .zIndex(10)
            }

            if viewModel.showTimerExpiredOverlay {
                overlayBackground
                OverlayNotificationView(
                    icon: "timer",
                    title: "Time's Up!",
                    subtitle: "You counted \(session.count) taps in \(session.formattedElapsedTime)",
                    color: .orange
                )
                .transition(.scale(scale: 0.8).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .navigationBarHidden(true)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.showTargetReachedOverlay)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.showTimerExpiredOverlay)
        .confirmationDialog("Delete this counting session?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Session", role: .destructive) {
                viewModel.deleteSession()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: viewModel.shouldDismissScreen) { oldValue, newValue in
            if newValue {
                dismiss()
            }
        }
        .onAppear {
            if !session.isCompleted {
                LiveActivityManager.shared.startLiveActivity(for: session)
            }
        }
        .onDisappear {
            LiveActivityManager.shared.endLiveActivity()
        }
    }

    // MARK: - Subviews

    private var overlayBackground: some View {
        Color.black.opacity(0.35)
            .ignoresSafeArea()
            .zIndex(9)
    }

    private var tapZone: some View {
        Color.clear
            .contentShape(Rectangle())
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.08)) { isTapAreaActive = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    isTapAreaActive = false
                }
                viewModel.tap()
            }
    }

    private var topBar: some View {
        HStack {
            // Back — keeps session alive in "In Progress"
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }

            Spacer()

            Text(session.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 8) {
                // Delete session
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 34, height: 34)
                        .background(.ultraThinMaterial, in: Circle())
                }

                // End session — moves it to history
                Button {
                    viewModel.completeSession()
                    dismiss()
                } label: {
                    Text("End")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.red.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var counterCenter: some View {
        ZStack {
            // Circular progress ring (for target and timer modes)
            if let progress = session.progress {
                CircularProgressView(
                    progress: progress,
                    lineWidth: 8,
                    size: 260,
                    color: accentColor
                )
            }

            VStack(spacing: 12) {
                // Big count number
                Text("\(session.count)")
                    .font(.system(size: 96, weight: .thin, design: .rounded))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText(countsDown: false))
                    .animation(.easeOut(duration: 0.15), value: session.count)
                    .monospacedDigit()

                // Timer display (timer mode)
                if session.mode == .timer {
                    VStack(spacing: 4) {
                        if let remaining = session.formattedRemainingTime {
                            HStack(spacing: 6) {
                                Image(systemName: "timer")
                                    .font(.caption)
                                    .foregroundColor(session.isTimerExpired ? .red : accentColor)
                                Text(session.isTimerExpired ? "Time's up" : remaining)
                                    .font(.system(.subheadline, design: .monospaced))
                                    .foregroundColor(session.isTimerExpired ? .red : .secondary)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }

                // Target display (target mode)
                if session.mode == .target, let target = session.targetCount {
                    Text("\(session.count) / \(target)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }
            }
        }
        .frame(width: 280, height: 280)
        .scaleEffect(isTapAreaActive ? 0.97 : 1.0)
        .animation(.easeOut(duration: 0.08), value: isTapAreaActive)
    }

    private var bottomControls: some View {
        HStack(spacing: 20) {
            UtilityButton(
                icon: "minus",
                label: "Subtract",
                color: .secondary
            ) {
                viewModel.subtract()
            }

            Spacer()

            // Center: tap hint
            VStack(spacing: 6) {
                Image(systemName: "hand.tap")
                    .font(.system(size: 24, weight: .ultraLight))
                    .foregroundColor(.primary.opacity(0.2))
                Text("Tap anywhere")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.5))
            }

            Spacer()

            UtilityButton(
                icon: "arrow.counterclockwise",
                label: "Reset",
                color: .secondary
            ) {
                viewModel.reset()
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Preview
#Preview {
    let session = TapSession(name: "Morning Meditation", mode: .target, targetCount: 108)
    return TapCounterView(viewModel: TapSessionViewModel(session: session))
}
