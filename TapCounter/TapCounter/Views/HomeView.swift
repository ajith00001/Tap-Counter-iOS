import SwiftUI

// MARK: - Home / Session List Screen
struct HomeView: View {
    @ObservedObject private var store = TapStore.shared
    @State private var showNewSessionSheet = false
    @State private var activeSession: TapSession? = nil
    @State private var navigateToSession = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: []) {
                        // MARK: - Create New / Start CTA
                        createNewCard
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        // MARK: - Active Sessions
                        if !store.activeSessions.isEmpty {
                            sectionHeader("In Progress", icon: "bolt.fill", color: .blue)
                                .padding(.top, 28)

                            VStack(spacing: 0) {
                                ForEach(store.activeSessions) { session in
                                    HStack {
                                        SessionRowView(session: session) {
                                            withAnimation {
                                                store.deleteActiveSession(id: session.id)
                                            }
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        activeSession = session
                                        navigateToSession = true
                                    }
                                    .padding(.horizontal, 20)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                store.deleteActiveSession(id: session.id)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }

                                    if session.id != store.activeSessions.last?.id {
                                        Divider()
                                            .padding(.leading, 84)
                                            .padding(.trailing, 20)
                                    }
                                }
                            }
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        }

                        // MARK: - Templates
                        if !store.templates.isEmpty {
                            sectionHeader("Templates", icon: "rectangle.stack", color: .secondary)
                                .padding(.top, 28)

                            VStack(spacing: 0) {
                                ForEach(Array(store.templates.enumerated()), id: \.element.id) { index, template in
                                    TemplateRowView(template: template) {
                                        let session = store.startSession(from: template)
                                        activeSession = session
                                        navigateToSession = true
                                    } onDelete: {
                                        withAnimation {
                                            store.deleteTemplate(id: template.id)
                                        }
                                    }
                                    .padding(.horizontal, 20)

                                    if index < store.templates.count - 1 {
                                        Divider()
                                            .padding(.leading, 84)
                                            .padding(.trailing, 20)
                                    }
                                }
                            }
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        }

                        // MARK: - History (Completed Sessions)
                        if !store.completedSessions.isEmpty {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("HISTORY")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                        .tracking(0.5)
                                }
                                Spacer()
                                Button {
                                    withAnimation {
                                        store.clearAllCompletedSessions()
                                    }
                                } label: {
                                    Text("Clear All")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 28)

                            VStack(spacing: 0) {
                                ForEach(Array(store.completedSessions.prefix(20).enumerated()), id: \.element.id) { index, session in
                                    CompletedSessionRowView(session: session) {
                                        withAnimation {
                                            store.deleteCompletedSession(id: session.id)
                                        }
                                    }
                                    .padding(.horizontal, 20)

                                    if index < min(store.completedSessions.count, 20) - 1 {
                                        Divider()
                                            .padding(.leading, 84)
                                            .padding(.trailing, 20)
                                    }
                                }
                            }
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        }

                        // MARK: - Empty state
                        if store.activeSessions.isEmpty && store.templates.isEmpty && store.completedSessions.isEmpty {
                            emptyState
                                .padding(.top, 60)
                        }

                        Spacer(minLength: 40)

                    }
                }
            }
            .navigationTitle("Tap Counter")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $navigateToSession) {
                if let session = activeSession {
                    TapCounterView(
                        viewModel: TapSessionViewModel(session: session, store: store)
                    )
                }
            }
            .sheet(isPresented: $showNewSessionSheet) {
                NewSessionSheet(store: store) { session in
                    activeSession = session
                    navigateToSession = true
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }

    // MARK: - Deep Link Routing
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "tapcounter" else { return }
        let urlString = url.absoluteString
        let cleanId = urlString
            .replacingOccurrences(of: "tapcounter://session/", with: "")
            .replacingOccurrences(of: "tapcounter://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        if let matchingSession = store.activeSessions.first(where: { $0.id.uuidString.caseInsensitiveCompare(cleanId) == .orderedSame }) {
            self.activeSession = matchingSession
            self.navigateToSession = true
        } else if let firstActive = store.activeSessions.first {
            self.activeSession = firstActive
            self.navigateToSession = true
        }
    }

    // MARK: - Create New Card
    private var createNewCard: some View {
        Button {
            showNewSessionSheet = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.accentColor)
                        .frame(width: 52, height: 52)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Start Counting")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text("Simple, target, or timer-based")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Section Header
    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .tracking(0.5)
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "hand.tap")
                    .font(.system(size: 40, weight: .ultraLight))
                    .foregroundColor(.accentColor.opacity(0.6))
            }

            VStack(spacing: 8) {
                Text("No sessions yet")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text("Tap \"Start Counting\" to begin your first counting session.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView()
}
