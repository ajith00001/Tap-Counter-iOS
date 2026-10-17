import Foundation
import Combine

// MARK: - Session ViewModel
class TapSessionViewModel: ObservableObject {
    @Published var session: TapSession
    @Published var showTargetReachedOverlay: Bool = false
    @Published var showTimerExpiredOverlay: Bool = false
    @Published var shouldDismissScreen: Bool = false

    private var timer: Timer?
    private var store: TapStore
    private var hapticService = HapticService.shared

    private var hasNotifiedTarget = false
    private var hasNotifiedTimerExpiry = false

    init(session: TapSession, store: TapStore = .shared) {
        self.session = session
        self.store = store

        if session.mode == .timer && !session.isCompleted {
            startTimer()
        }
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Tap Actions
    func tap() {
        guard !session.isTimerExpired else { return }

        session.count += 1
        hapticService.tapFeedback()

        // Check target reached
        if session.mode == .target,
           let target = session.targetCount,
           session.count >= target,
           !hasNotifiedTarget {
            hasNotifiedTarget = true
            hapticService.targetReachedFeedback()
            showTargetReachedOverlay = true
            // Auto complete and exit session after 1.6s of celebration
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
                guard let self = self else { return }
                self.showTargetReachedOverlay = false
                self.completeSession()
                self.shouldDismissScreen = true
            }
        }

        saveSession()
        LiveActivityManager.shared.updateLiveActivity(for: session)
        PhoneWatchSyncManager.shared.syncSession(session)
    }

    func subtract() {
        guard session.count > 0 else { return }
        session.count -= 1
        hasNotifiedTarget = session.count < (session.targetCount ?? Int.max)
        hapticService.subtractFeedback()
        saveSession()
        LiveActivityManager.shared.updateLiveActivity(for: session)
        PhoneWatchSyncManager.shared.syncSession(session)
    }

    func reset() {
        session.count = 0
        hasNotifiedTarget = false
        showTargetReachedOverlay = false
        hapticService.resetFeedback()
        saveSession()
        LiveActivityManager.shared.updateLiveActivity(for: session)
        PhoneWatchSyncManager.shared.syncSession(session)
    }

    func completeSession() {
        timer?.invalidate()
        timer = nil
        LiveActivityManager.shared.endLiveActivity()
        PhoneWatchSyncManager.shared.syncSessionEnded(id: session.id)
        store.completeSession(session)
    }

    func deleteSession() {
        timer?.invalidate()
        timer = nil
        LiveActivityManager.shared.endLiveActivity()
        PhoneWatchSyncManager.shared.syncSessionEnded(id: session.id)
        store.deleteActiveSession(id: session.id)
    }

    // MARK: - Timer
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
    }

    private func timerTick() {
        guard let duration = session.timerDuration else { return }
        session.elapsedTime += 1.0

        if session.elapsedTime >= duration && !hasNotifiedTimerExpiry {
            hasNotifiedTimerExpiry = true
            hapticService.timerExpiredFeedback()
            showTimerExpiredOverlay = true
            timer?.invalidate()
            timer = nil
            // Auto complete and exit session after 1.8s
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
                guard let self = self else { return }
                self.showTimerExpiredOverlay = false
                self.completeSession()
                self.shouldDismissScreen = true
            }
        }

        saveSession()
        LiveActivityManager.shared.updateLiveActivity(for: session)
    }

    // MARK: - Persistence
    private func saveSession() {
        store.updateSession(session)
    }
}
