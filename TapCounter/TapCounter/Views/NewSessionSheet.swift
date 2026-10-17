import SwiftUI

// MARK: - New Template / Session Sheet
struct NewSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: TapStore

    var onStart: (TapSession) -> Void

    @State private var selectedMode: TapCounterMode = .simple
    @State private var name: String = ""
    @State private var targetCount: String = "100"
    @State private var timerHours: Int = 0
    @State private var timerMinutes: Int = 5
    @State private var timerSeconds: Int = 0
    @State private var saveAsTemplate: Bool = false

    private var isValid: Bool {
        // Name is purely optional, fallback resolvedName is used if blank
        if selectedMode == .target {
            guard let t = Int(targetCount), t > 0 else { return false }
        }
        if selectedMode == .timer {
            if timerHours == 0 && timerMinutes == 0 && timerSeconds == 0 { return false }
        }
        return true
    }

    private var resolvedName: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            switch selectedMode {
            case .simple: return "Quick Count"
            case .target: return "Target Count"
            case .timer: return "Timed Count"
            }
        }
        return trimmed
    }

    var body: some View {
        NavigationView {
            Form {
                // Mode Picker
                Section {
                    Picker("Mode", selection: $selectedMode) {
                        ForEach(TapCounterMode.allCases, id: \.self) { mode in
                            Label(mode.rawValue, systemImage: mode.icon)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Counting Mode")
                }

                // Mode description
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: selectedMode.icon)
                            .font(.title2)
                            .foregroundColor(modeColor)
                            .frame(width: 36)
                        Text(selectedMode.description)
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                    .listRowBackground(modeColor.opacity(0.06))
                }

                // Name field
                Section("Name (optional)") {
                    TextField(resolvedName, text: $name)
                        .autocorrectionDisabled()
                }

                // Mode-specific options
                if selectedMode == .target {
                    Section("Target Count") {
                        HStack {
                            Text("Taps to reach")
                            Spacer()
                            TextField("100", text: $targetCount)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .foregroundColor(modeColor)
                                .fontWeight(.medium)
                        }
                    }
                }

                if selectedMode == .timer {
                    Section {
                        PreciseTimerPicker(hours: $timerHours, minutes: $timerMinutes, seconds: $timerSeconds)
                            .frame(height: 160)
                            .listRowInsets(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                    } header: {
                        Text("Timer Duration")
                    }
                }

                // Save as template toggle
                Section {
                    Toggle("Save as Template", isOn: $saveAsTemplate)
                        .tint(modeColor)
                } footer: {
                    Text("Templates can be reused to quickly start new counting sessions.")
                }
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        startSession()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(isValid ? modeColor : .secondary)
                    .disabled(!isValid)
                }
            }
        }
    }

    private var modeColor: Color {
        switch selectedMode {
        case .simple: return .blue
        case .target: return .green
        case .timer: return .orange
        }
    }

    private func startSession() {
        let finalName = resolvedName
        var session: TapSession

        switch selectedMode {
        case .simple:
            if saveAsTemplate {
                let template = TapTemplate.makeSimple(name: finalName)
                store.addTemplate(template)
                session = store.startSession(from: template)
            } else {
                session = store.startQuickSession(mode: .simple, name: finalName)
            }

        case .target:
            let target = Int(targetCount) ?? 100
            if saveAsTemplate {
                let template = TapTemplate.makeTarget(name: finalName, target: target)
                store.addTemplate(template)
                session = store.startSession(from: template)
            } else {
                session = store.startQuickSession(mode: .target, name: finalName, targetCount: target)
            }

        case .timer:
            let totalSeconds = TimeInterval(timerHours * 3600 + timerMinutes * 60 + timerSeconds)
            let duration = max(totalSeconds, 1)
            if saveAsTemplate {
                let template = TapTemplate.makeTimer(name: finalName, duration: duration)
                store.addTemplate(template)
                session = store.startSession(from: template)
            } else {
                session = store.startQuickSession(mode: .timer, name: finalName, timerDuration: duration)
            }
        }

        dismiss()
        onStart(session)
    }
}

// MARK: - Preview
#Preview {
    NewSessionSheet(store: .shared) { _ in }
}
