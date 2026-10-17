import SwiftUI

// MARK: - Session List Row
struct SessionRowView: View {
    @ObservedObject var session: TapSession
    var onDelete: (() -> Void)? = nil

    var accentColor: Color {
        switch session.mode {
        case .simple: return .blue
        case .target: return .green
        case .timer: return .orange
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Progress indicator or mode icon
            ZStack {
                if let progress = session.progress {
                    CircularProgressView(
                        progress: progress,
                        lineWidth: 3,
                        size: 44,
                        color: accentColor
                    )
                    Text("\(session.progressPercentage ?? 0)%")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(accentColor)
                } else {
                    Circle()
                        .fill(accentColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: session.mode.icon)
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(accentColor)
                }
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    ModeBadge(mode: session.mode)

                    if session.mode == .timer, let remaining = session.formattedRemainingTime {
                        HStack(spacing: 3) {
                            Image(systemName: "timer")
                                .font(.caption2)
                            Text(remaining)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .monospacedDigit()
                        }
                        .foregroundColor(session.isTimerExpired ? .red : .secondary)
                    }
                }
            }

            Spacer()

            HStack(spacing: 12) {
                // Count display
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(session.count)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: false))

                    if session.mode == .target, let target = session.targetCount {
                        Text("of \(target)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 34, height: 34)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.5))
            }
        }
        .padding(.vertical, 10)
        .contextMenu {
            if let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete Session", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Template Row
struct TemplateRowView: View {
    let template: TapTemplate
    let onStart: () -> Void
    let onDelete: () -> Void

    var accentColor: Color {
        switch template.mode {
        case .simple: return .blue
        case .target: return .green
        case .timer: return .orange
        }
    }

    var subtitle: String {
        switch template.mode {
        case .simple:
            return "Simple counting"
        case .target:
            return "Target: \(template.targetCount ?? 0) taps"
        case .timer:
            guard let d = template.timerDuration else { return "Timed" }
            let hours = Int(d) / 3600
            let mins = (Int(d) % 3600) / 60
            let secs = Int(d) % 60
            if hours > 0 {
                return "\(hours)h \(mins > 0 ? "\(mins)m " : "")\(secs > 0 ? "\(secs)s " : "")timer"
            }
            if mins > 0 { return "\(mins)m \(secs > 0 ? "\(secs)s " : "")timer" }
            return "\(secs)s timer"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: template.mode.icon)
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(template.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                // Delete template button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 34, height: 34)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                // Start button
                Button(action: onStart) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 13))
                        .foregroundColor(accentColor)
                        .frame(width: 36, height: 36)
                        .background(accentColor.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            onStart()
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete Template", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Completed Session Row
struct CompletedSessionRowView: View {
    let session: TapSession
    var onDelete: (() -> Void)? = nil

    var accentColor: Color {
        switch session.mode {
        case .simple: return .blue
        case .target: return .green
        case .timer: return .orange
        }
    }

    var durationText: String {
        guard let completed = session.completedAt else { return "" }
        let duration = completed.timeIntervalSince(session.startedAt)
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        if mins > 0 { return "\(mins)m \(secs)s" }
        return "\(secs)s"
    }

    var dateText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: session.startedAt, relativeTo: Date())
    }

    var body: some View {
        HStack(spacing: 14) {
            // Mode icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.08))
                    .frame(width: 44, height: 44)
                Image(systemName: session.mode.icon)
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(accentColor.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    ModeBadge(mode: session.mode)
                    Text("·")
                        .foregroundColor(.secondary)
                        .font(.caption2)
                    Text(dateText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    if !durationText.isEmpty {
                        Text("·")
                            .foregroundColor(.secondary)
                            .font(.caption2)
                        Text(durationText)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            HStack(spacing: 12) {
                // Final count
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(session.count)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                    Text("taps")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.6))
                }

                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 34, height: 34)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 8)
        .contextMenu {
            if let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete From History", systemImage: "trash")
                }
            }
        }
    }
}
