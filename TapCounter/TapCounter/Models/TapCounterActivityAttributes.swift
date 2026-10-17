import ActivityKit
import Foundation

public struct TapCounterActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var count: Int
        public var elapsedTime: TimeInterval
        public var isCompleted: Bool

        public init(count: Int, elapsedTime: TimeInterval = 0, isCompleted: Bool = false) {
            self.count = count
            self.elapsedTime = elapsedTime
            self.isCompleted = isCompleted
        }
    }

    // Static context for the activity
    public var sessionId: String
    public var sessionName: String
    public var mode: String          // "Simple", "Target", "Timer"
    public var targetCount: Int?
    public var timerDuration: TimeInterval?

    public init(sessionId: String, sessionName: String, mode: String, targetCount: Int? = nil, timerDuration: TimeInterval? = nil) {
        self.sessionId = sessionId
        self.sessionName = sessionName
        self.mode = mode
        self.targetCount = targetCount
        self.timerDuration = timerDuration
    }
}
