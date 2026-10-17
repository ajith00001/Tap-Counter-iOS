import Foundation
import SwiftUI

// MARK: - Tap Counter Mode
enum TapCounterMode: String, Codable, CaseIterable {
    case simple = "Simple"
    case target = "Target"
    case timer = "Timer"

    var icon: String {
        switch self {
        case .simple: return "hand.tap"
        case .target: return "target"
        case .timer: return "timer"
        }
    }

    var description: String {
        switch self {
        case .simple: return "Count taps freely"
        case .target: return "Count towards a goal"
        case .timer: return "Count within a time limit"
        }
    }
}

// MARK: - Tap Template
struct TapTemplate: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var mode: TapCounterMode
    var targetCount: Int?      // Used for .target mode
    var timerDuration: TimeInterval?  // Used for .timer mode (in seconds)
    var createdAt: Date = Date()

    static func makeSimple(name: String) -> TapTemplate {
        TapTemplate(name: name, mode: .simple)
    }

    static func makeTarget(name: String, target: Int) -> TapTemplate {
        TapTemplate(name: name, mode: .target, targetCount: target)
    }

    static func makeTimer(name: String, duration: TimeInterval) -> TapTemplate {
        TapTemplate(name: name, mode: .timer, timerDuration: duration)
    }
}

// MARK: - Tap Session
class TapSession: Identifiable, ObservableObject, Codable {
    var id: UUID = UUID()
    var templateId: UUID?
    var name: String
    var mode: TapCounterMode
    var targetCount: Int?
    var timerDuration: TimeInterval?

    @Published var count: Int = 0
    @Published var isCompleted: Bool = false
    @Published var startedAt: Date = Date()
    @Published var completedAt: Date?
    @Published var elapsedTime: TimeInterval = 0  // For timer mode: tracks time elapsed

    // Computed properties
    var progress: Double? {
        switch mode {
        case .simple:
            return nil
        case .target:
            guard let target = targetCount, target > 0 else { return nil }
            return min(Double(count) / Double(target), 1.0)
        case .timer:
            guard let duration = timerDuration, duration > 0 else { return nil }
            return min(elapsedTime / duration, 1.0)
        }
    }

    var progressPercentage: Int? {
        guard let p = progress else { return nil }
        return Int(p * 100)
    }

    var isTimerExpired: Bool {
        guard mode == .timer, let duration = timerDuration else { return false }
        return elapsedTime >= duration
    }

    var remainingTime: TimeInterval? {
        guard mode == .timer, let duration = timerDuration else { return nil }
        return max(duration - elapsedTime, 0)
    }

    var formattedRemainingTime: String? {
        guard let t = remainingTime else { return nil }
        let hours = Int(t) / 3600
        let minutes = (Int(t) % 3600) / 60
        let seconds = Int(t) % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    init(template: TapTemplate) {
        self.templateId = template.id
        self.name = template.name
        self.mode = template.mode
        self.targetCount = template.targetCount
        self.timerDuration = template.timerDuration
    }

    init(name: String, mode: TapCounterMode, targetCount: Int? = nil, timerDuration: TimeInterval? = nil) {
        self.name = name
        self.mode = mode
        self.targetCount = targetCount
        self.timerDuration = timerDuration
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, templateId, name, mode, targetCount, timerDuration
        case count, isCompleted, startedAt, completedAt, elapsedTime
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        templateId = try container.decodeIfPresent(UUID.self, forKey: .templateId)
        name = try container.decode(String.self, forKey: .name)
        mode = try container.decode(TapCounterMode.self, forKey: .mode)
        targetCount = try container.decodeIfPresent(Int.self, forKey: .targetCount)
        timerDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .timerDuration)
        count = try container.decode(Int.self, forKey: .count)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        elapsedTime = try container.decode(TimeInterval.self, forKey: .elapsedTime)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(templateId, forKey: .templateId)
        try container.encode(name, forKey: .name)
        try container.encode(mode, forKey: .mode)
        try container.encodeIfPresent(targetCount, forKey: .targetCount)
        try container.encodeIfPresent(timerDuration, forKey: .timerDuration)
        try container.encode(count, forKey: .count)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(startedAt, forKey: .startedAt)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encode(elapsedTime, forKey: .elapsedTime)
    }
}
