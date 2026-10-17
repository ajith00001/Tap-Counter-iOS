import Foundation
import WatchConnectivity
import Combine

class PhoneWatchSyncManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = PhoneWatchSyncManager()

    private var session: WCSession?

    private override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
            return
        }
        print("WCSession activated on iPhone with state: \(activationState.rawValue)")
        if activationState == .activated {
            syncCurrentState()
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate for multi-watch support
        session.activate()
    }

    // Broadcast session update to watch
    func syncSession(_ tapSession: TapSession) {
        guard let session = session, session.activationState == .activated else { return }

        var data: [String: Any] = [
            "action": "sessionUpdated",
            "id": tapSession.id.uuidString,
            "name": tapSession.name,
            "mode": tapSession.mode.rawValue,
            "count": tapSession.count,
            "elapsedTime": tapSession.elapsedTime,
            "isCompleted": tapSession.isCompleted
        ]

        if let target = tapSession.targetCount {
            data["targetCount"] = target
        }
        if let duration = tapSession.timerDuration {
            data["timerDuration"] = duration
        }

        // Live immediate message if watch app is currently reachable
        if session.isReachable {
            session.sendMessage(data, replyHandler: nil) { error in
                print("Error sending message to watch: \(error.localizedDescription)")
            }
        }

        // Background application context so watch gets updated state when opened
        do {
            try session.updateApplicationContext(data)
        } catch {
            print("Failed to update application context: \(error.localizedDescription)")
        }
    }

    func syncSessionEnded(id: UUID) {
        guard let session = session, session.activationState == .activated else { return }
        let data: [String: Any] = [
            "action": "sessionEnded",
            "id": id.uuidString
        ]
        if session.isReachable {
            session.sendMessage(data, replyHandler: nil, errorHandler: nil)
        }
        try? session.updateApplicationContext(data)
    }

    func syncCurrentState() {
        if let active = TapStore.shared.activeSessions.first {
            syncSession(active)
        } else {
            let data: [String: Any] = ["action": "noActiveSession"]
            if session?.isReachable == true {
                session?.sendMessage(data, replyHandler: nil, errorHandler: nil)
            }
            try? session?.updateApplicationContext(data)
        }
    }

    // Handle actions sent from the Watch
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        handleIncomingMessage(message, replyHandler: replyHandler)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleIncomingMessage(message, replyHandler: nil)
    }

    private func handleIncomingMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
        guard let action = message["action"] as? String else { return }

        DispatchQueue.main.async {
            switch action {
            case "tap":
                if let idStr = message["id"] as? String,
                   let id = UUID(uuidString: idStr),
                   let tapSession = TapStore.shared.activeSessions.first(where: { $0.id == id }) {
                    tapSession.count += 1
                    TapStore.shared.updateSession(tapSession)
                    LiveActivityManager.shared.updateLiveActivity(for: tapSession)
                    HapticService.shared.tapFeedback()
                    replyHandler?(["status": "ok", "count": tapSession.count])
                } else if let firstActive = TapStore.shared.activeSessions.first {
                    firstActive.count += 1
                    TapStore.shared.updateSession(firstActive)
                    LiveActivityManager.shared.updateLiveActivity(for: firstActive)
                    HapticService.shared.tapFeedback()
                    replyHandler?(["status": "ok", "count": firstActive.count])
                }

            case "subtract":
                if let idStr = message["id"] as? String,
                   let id = UUID(uuidString: idStr),
                   let tapSession = TapStore.shared.activeSessions.first(where: { $0.id == id }),
                   tapSession.count > 0 {
                    tapSession.count -= 1
                    TapStore.shared.updateSession(tapSession)
                    LiveActivityManager.shared.updateLiveActivity(for: tapSession)
                    HapticService.shared.subtractFeedback()
                    replyHandler?(["status": "ok", "count": tapSession.count])
                }

            case "reset":
                if let idStr = message["id"] as? String,
                   let id = UUID(uuidString: idStr),
                   let tapSession = TapStore.shared.activeSessions.first(where: { $0.id == id }) {
                    tapSession.count = 0
                    TapStore.shared.updateSession(tapSession)
                    LiveActivityManager.shared.updateLiveActivity(for: tapSession)
                    HapticService.shared.resetFeedback()
                    replyHandler?(["status": "ok", "count": 0])
                }

            case "end":
                if let idStr = message["id"] as? String,
                   let id = UUID(uuidString: idStr),
                   let tapSession = TapStore.shared.activeSessions.first(where: { $0.id == id }) {
                    TapStore.shared.completeSession(tapSession)
                    LiveActivityManager.shared.endLiveActivity()
                    replyHandler?(["status": "ok"])
                }

            case "startSession":
                let modeStr = message["mode"] as? String ?? "Simple"
                let mode = TapCounterMode(rawValue: modeStr) ?? .simple
                let name = message["name"] as? String ?? "\(mode.rawValue) Session"
                let target = message["targetCount"] as? Int
                let duration = message["timerDuration"] as? TimeInterval
                let newSession = TapStore.shared.startQuickSession(
                    mode: mode,
                    name: name,
                    targetCount: target,
                    timerDuration: duration
                )
                self.syncSession(newSession)
                replyHandler?([
                    "status": "ok",
                    "id": newSession.id.uuidString,
                    "count": newSession.count,
                    "name": newSession.name
                ])

            case "requestCurrentState":
                if let active = TapStore.shared.activeSessions.first {
                    var response: [String: Any] = [
                        "status": "ok",
                        "id": active.id.uuidString,
                        "name": active.name,
                        "mode": active.mode.rawValue,
                        "count": active.count,
                        "elapsedTime": active.elapsedTime,
                        "isCompleted": active.isCompleted
                    ]
                    if let target = active.targetCount { response["targetCount"] = target }
                    if let dur = active.timerDuration { response["timerDuration"] = dur }
                    replyHandler?(response)
                } else {
                    replyHandler?(["status": "noActiveSession"])
                }

            default:
                break
            }
        }
    }
}
