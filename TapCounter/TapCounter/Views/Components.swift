import SwiftUI

// MARK: - Circular Progress View
struct CircularProgressView: View {
    let progress: Double       // 0.0 to 1.0
    let lineWidth: CGFloat
    let size: CGFloat
    let color: Color

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)
        }
    }
}

// MARK: - Mode Badge
struct ModeBadge: View {
    let mode: TapCounterMode

    var color: Color {
        switch mode {
        case .simple: return .blue
        case .target: return .green
        case .timer: return .orange
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: mode.icon)
                .font(.caption2)
            Text(mode.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Overlay Notification View
struct OverlayNotificationView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundColor(color)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        .transition(.scale(scale: 0.8).combined(with: .opacity))
    }
}

// MARK: - Utility Icon Button
struct UtilityButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                Text(label)
                    .font(.caption)
                    .foregroundColor(color.opacity(0.8))
            }
            .frame(width: 64, height: 64)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - 3-Column Time Picker (Hours, Minutes, Seconds) with native Apple Clock feel
struct PreciseTimerPicker: UIViewRepresentable {
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        picker.selectRow(hours, inComponent: 0, animated: false)
        picker.selectRow(minutes, inComponent: 1, animated: false)
        picker.selectRow(seconds, inComponent: 2, animated: false)
        return picker
    }

    func updateUIView(_ picker: UIPickerView, context: Context) {
        if picker.selectedRow(inComponent: 0) != hours {
            picker.selectRow(hours, inComponent: 0, animated: false)
        }
        if picker.selectedRow(inComponent: 1) != minutes {
            picker.selectRow(minutes, inComponent: 1, animated: false)
        }
        if picker.selectedRow(inComponent: 2) != seconds {
            picker.selectRow(seconds, inComponent: 2, animated: false)
        }
    }

    class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: PreciseTimerPicker

        init(_ parent: PreciseTimerPicker) {
            self.parent = parent
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            3
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            switch component {
            case 0: return 24
            case 1: return 60
            case 2: return 60
            default: return 0
            }
        }

        func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
            return 95
        }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            return 36
        }

        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let container = UIView(frame: CGRect(x: 0, y: 0, width: 95, height: 36))

            let numLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 44, height: 36))
            numLabel.text = "\(row)"
            numLabel.textAlignment = .right
            numLabel.font = UIFont.systemFont(ofSize: 22, weight: .regular)
            numLabel.textColor = UIColor.label
            container.addSubview(numLabel)

            let unitLabel = UILabel(frame: CGRect(x: 48, y: 3, width: 45, height: 33))
            switch component {
            case 0: unitLabel.text = "hours"
            case 1: unitLabel.text = "min"
            case 2: unitLabel.text = "sec"
            default: break
            }
            unitLabel.textAlignment = .left
            unitLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            unitLabel.textColor = UIColor.secondaryLabel
            container.addSubview(unitLabel)

            return container
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            switch component {
            case 0: parent.hours = row
            case 1: parent.minutes = row
            case 2: parent.seconds = row
            default: break
            }
        }
    }
}
