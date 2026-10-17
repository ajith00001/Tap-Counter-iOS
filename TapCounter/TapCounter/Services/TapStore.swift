import Foundation
import Combine

// MARK: - Store (Persistence)
class TapStore: ObservableObject {
    static let shared = TapStore()

    @Published var templates: [TapTemplate] = []
    @Published var activeSessions: [TapSession] = []
    @Published var completedSessions: [TapSession] = []

    private let templatesKey = "tap_templates"
    private let activeSessionsKey = "tap_active_sessions"
    private let completedSessionsKey = "tap_completed_sessions"

    private init() {
        load()
    }

    // MARK: - Template Operations
    func addTemplate(_ template: TapTemplate) {
        templates.append(template)
        saveTemplates()
    }

    func deleteTemplate(at offsets: IndexSet) {
        templates.remove(atOffsets: offsets)
        saveTemplates()
    }

    func deleteTemplate(id: UUID) {
        templates.removeAll { $0.id == id }
        saveTemplates()
    }

    // MARK: - Session Operations
    func startSession(from template: TapTemplate) -> TapSession {
        let session = TapSession(template: template)
        activeSessions.append(session)
        saveActiveSessions()
        return session
    }

    func startQuickSession(mode: TapCounterMode, name: String, targetCount: Int? = nil, timerDuration: TimeInterval? = nil) -> TapSession {
        let session = TapSession(name: name, mode: mode, targetCount: targetCount, timerDuration: timerDuration)
        activeSessions.append(session)
        saveActiveSessions()
        return session
    }

    func completeSession(_ session: TapSession) {
        session.isCompleted = true
        session.completedAt = Date()
        activeSessions.removeAll { $0.id == session.id }
        completedSessions.insert(session, at: 0)
        saveActiveSessions()
        saveCompletedSessions()
    }

    func updateSession(_ session: TapSession) {
        objectWillChange.send()
        saveActiveSessions()
    }

    func deleteActiveSession(id: UUID) {
        activeSessions.removeAll { $0.id == id }
        saveActiveSessions()
    }

    func deleteCompletedSession(at offsets: IndexSet) {
        completedSessions.remove(atOffsets: offsets)
        saveCompletedSessions()
    }

    func deleteCompletedSession(id: UUID) {
        completedSessions.removeAll { $0.id == id }
        saveCompletedSessions()
    }

    func clearAllCompletedSessions() {
        completedSessions.removeAll()
        saveCompletedSessions()
    }

    // MARK: - Persistence
    private func load() {
        loadTemplates()
        loadActiveSessions()
        loadCompletedSessions()
    }

    private func saveTemplates() {
        if let data = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(data, forKey: templatesKey)
        }
    }

    private func loadTemplates() {
        if let data = UserDefaults.standard.data(forKey: templatesKey),
           let decoded = try? JSONDecoder().decode([TapTemplate].self, from: data) {
            templates = decoded
        }
    }

    private func saveActiveSessions() {
        if let data = try? JSONEncoder().encode(activeSessions) {
            UserDefaults.standard.set(data, forKey: activeSessionsKey)
        }
    }

    private func loadActiveSessions() {
        if let data = UserDefaults.standard.data(forKey: activeSessionsKey),
           let decoded = try? JSONDecoder().decode([TapSession].self, from: data) {
            activeSessions = decoded
        }
    }

    private func saveCompletedSessions() {
        if let data = try? JSONEncoder().encode(completedSessions) {
            UserDefaults.standard.set(data, forKey: completedSessionsKey)
        }
    }

    private func loadCompletedSessions() {
        if let data = UserDefaults.standard.data(forKey: completedSessionsKey),
           let decoded = try? JSONDecoder().decode([TapSession].self, from: data) {
            completedSessions = decoded
        }
    }
}
