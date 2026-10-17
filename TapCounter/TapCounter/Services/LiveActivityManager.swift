import ActivityKit
import Foundation

class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var currentActivity: Activity<TapCounterActivityAttributes>?

    private init() {}

    func startLiveActivity(for session: TapSession) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled by user")
            return
        }

        // Reuse existing activity for this session if already running
        if let existing = Activity<TapCounterActivityAttributes>.activities.first(where: { $0.attributes.sessionId == session.id.uuidString }) {
            self.currentActivity = existing
            updateLiveActivity(for: session)
            return
        }

        // End any prior activity from a different session
        endLiveActivity()

        let attributes = TapCounterActivityAttributes(
            sessionId: session.id.uuidString,
            sessionName: session.name.isEmpty ? "\(session.mode.rawValue) Session" : session.name,
            mode: session.mode.rawValue,
            targetCount: session.targetCount,
            timerDuration: session.timerDuration
        )

        let initialContentState = TapCounterActivityAttributes.ContentState(
            count: session.count,
            elapsedTime: session.elapsedTime,
            isCompleted: session.isCompleted
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialContentState, staleDate: nil)
            )
            self.currentActivity = activity
            print("Requested Live Activity: \(activity.id)")
        } catch {
            print("Error requesting Live Activity: \(error.localizedDescription)")
        }
    }

    func updateLiveActivity(for session: TapSession) {
        let activity = currentActivity ?? Activity<TapCounterActivityAttributes>.activities.first(where: { $0.attributes.sessionId == session.id.uuidString })
        guard let act = activity else { return }

        let updatedContentState = TapCounterActivityAttributes.ContentState(
            count: session.count,
            elapsedTime: session.elapsedTime,
            isCompleted: session.isCompleted
        )

        Task {
            await act.update(.init(state: updatedContentState, staleDate: nil))
        }
    }

    func endLiveActivity() {
        Task {
            for activity in Activity<TapCounterActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        currentActivity = nil
    }
}
