import Foundation
import WatchConnectivity
import WatchKit
import Combine

struct WatchTapSession: Identifiable, Equatable {
    var id: UUID
    var name: String
    var mode: String // "Simple", "Target", "Timer"
    var count: Int
    var targetCount: Int?
    var timerDuration: TimeInterval?
    var elapsedTime: TimeInterval
    var isCompleted: Bool

    var progress: Double? {
        if mode == "Target", let target = targetCount, target > 0 {
            return min(Double(count) / Double(target), 1.0)
        } else if mode == "Timer", let dur = timerDuration, dur > 0 {
            return min(elapsedTime / dur, 1.0)
        }
        return nil
    }

    var remainingTime: TimeInterval? {
        guard mode == "Timer", let dur = timerDuration else { return nil }
        return max(dur - elapsedTime, 0)
    }

    var formattedRemainingTime: String? {
        guard let t = remainingTime else { return nil }
        let mins = Int(t) / 60
        let secs = Int(t) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()

    @Published var currentSession: WatchTapSession?
    @Published var isReachableWithPhone: Bool = false

    private var session: WCSession?
    private var timer: Timer?

    private override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
        startLocalTimer()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachableWithPhone = session.isReachable
            if activationState == .activated {
                self.requestStateFromPhone()
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachableWithPhone = session.isReachable
        }
    }

    // Tap action on watch
    func tap() {
        // Physical tactile click on wrist
        WKInterfaceDevice.current().play(.click)

        if var current = currentSession {
            current.count += 1
            if current.mode == "Target", let target = current.targetCount, current.count >= target {
                WKInterfaceDevice.current().play(.success)
            }
            self.currentSession = current
            sendActionToPhone("tap", sessionId: current.id)
        } else {
            // Start a quick session if none exists
            startQuickSession()
        }
    }

    func subtract() {
        guard var current = currentSession, current.count > 0 else { return }
        WKInterfaceDevice.current().play(.directionDown)
        current.count -= 1
        self.currentSession = current
        sendActionToPhone("subtract", sessionId: current.id)
    }

    func reset() {
        guard var current = currentSession else { return }
        WKInterfaceDevice.current().play(.retry)
        current.count = 0
        self.currentSession = current
        sendActionToPhone("reset", sessionId: current.id)
    }

    func endSession() {
        guard let current = currentSession else { return }
        WKInterfaceDevice.current().play(.stop)
        sendActionToPhone("end", sessionId: current.id)
        self.currentSession = nil
    }

    func startQuickSession(mode: String = "Simple", target: Int? = nil, duration: TimeInterval? = nil) {
        let newSession = WatchTapSession(
            id: UUID(),
            name: "\(mode) Session",
            mode: mode,
            count: 0,
            targetCount: target,
            timerDuration: duration,
            elapsedTime: 0,
            isCompleted: false
        )
        self.currentSession = newSession
        WKInterfaceDevice.current().play(.start)

        var data: [String: Any] = [
            "action": "startSession",
            "name": newSession.name,
            "mode": mode
        ]
        if let target = target { data["targetCount"] = target }
        if let duration = duration { data["timerDuration"] = duration }

        if let session = session, session.isReachable {
            session.sendMessage(data) { [weak self] reply in
                if let idStr = reply["id"] as? String, let id = UUID(uuidString: idStr) {
                    DispatchQueue.main.async {
                        self?.currentSession?.id = id
                    }
                }
            } errorHandler: { error in
                print("Error starting session on phone: \(error)")
            }
        }
    }

    private func sendActionToPhone(_ action: String, sessionId: UUID) {
        let msg: [String: Any] = [
            "action": action,
            "id": sessionId.uuidString
        ]
        if let session = session, session.isReachable {
            session.sendMessage(msg, replyHandler: nil) { error in
                print("Watch send error: \(error)")
            }
        }
    }

    func requestStateFromPhone() {
        guard let session = session, session.isReachable else { return }
        session.sendMessage(["action": "requestCurrentState"]) { [weak self] reply in
            DispatchQueue.main.async {
                self?.handleSessionDictionary(reply)
            }
        } errorHandler: { error in
            print("Failed to get state from phone: \(error)")
        }
    }

    // Handle updates received from phone
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.handleSessionDictionary(message)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            self.handleSessionDictionary(applicationContext)
        }
    }

    private func handleSessionDictionary(_ dict: [String: Any]) {
        if let action = dict["action"] as? String, action == "noActiveSession" || action == "sessionEnded" {
            self.currentSession = nil
            return
        }

        guard let idStr = dict["id"] as? String, let id = UUID(uuidString: idStr),
              let count = dict["count"] as? Int else {
            return
        }

        let name = dict["name"] as? String ?? "Tap Session"
        let mode = dict["mode"] as? String ?? "Simple"
        let target = dict["targetCount"] as? Int
        let duration = dict["timerDuration"] as? TimeInterval
        let elapsed = dict["elapsedTime"] as? TimeInterval ?? 0
        let completed = dict["isCompleted"] as? Bool ?? false

        self.currentSession = WatchTapSession(
            id: id,
            name: name,
            mode: mode,
            count: count,
            targetCount: target,
            timerDuration: duration,
            elapsedTime: elapsed,
            isCompleted: completed
        )
    }

    private func startLocalTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, var current = self.currentSession, current.mode == "Timer" else { return }
            current.elapsedTime += 1.0
            if let duration = current.timerDuration, current.elapsedTime >= duration {
                WKInterfaceDevice.current().play(.notification)
            }
            self.currentSession = current
        }
    }
}
