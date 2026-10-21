import SwiftUI

private enum PomodoroPalette {
    static let background = Color(red: 0.075, green: 0.09, blue: 0.13)
    static let card = Color(red: 0.12, green: 0.14, blue: 0.19)
    static let text = Color(red: 0.94, green: 0.95, blue: 0.98)
    static let muted = Color(red: 0.58, green: 0.62, blue: 0.70)

    static func color(for mode: PomodoroMode) -> Color {
        switch mode {
        case .focus: Color(red: 1.0, green: 0.39, blue: 0.34)
        case .shortBreak: Color(red: 0.30, green: 0.82, blue: 0.66)
        case .longBreak: Color(red: 0.39, green: 0.63, blue: 1.0)
        }
    }
}

struct MenuBarPanel: View {
    @ObservedObject var timer: PomodoroTimer
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label("POMODORO", systemImage: "timer")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(PomodoroPalette.muted)
                Spacer()
                Button { openSettings() } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .buttonStyle(.plain)
                .help("Settings")
            }

            TimerFace(timer: timer, compact: true)

            HStack(spacing: 10) {
                Button { timer.toggle() } label: {
                    Label(timer.isRunning ? "Pause" : "Start", systemImage: timer.isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryTimerButton(color: PomodoroPalette.color(for: timer.mode)))

                Button { timer.reset() } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .frame(width: 42, height: 40)
                }
                .buttonStyle(SecondaryTimerButton())
                .help("Reset")

                Button { timer.skip() } label: {
                    Image(systemName: "forward.end.fill")
                        .frame(width: 42, height: 40)
                }
                .buttonStyle(SecondaryTimerButton())
                .help("Skip phase")
            }

            HStack {
                Text("Session \(timer.completedFocusSessions % 4 + 1) of 4")
                Spacer()
                Button("Show floating timer") { openWindow(id: "floating-timer") }
                    .font(.system(size: 11, weight: .medium))
                    .buttonStyle(.plain)
                    .foregroundStyle(PomodoroPalette.color(for: timer.mode))
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(PomodoroPalette.muted)
        }
        .padding(18)
        .frame(width: 310)
        .background(PomodoroPalette.background)
    }
}

struct FloatingTimerView: View {
    @ObservedObject var timer: PomodoroTimer

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Label("POMODORO", systemImage: "timer")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(PomodoroPalette.muted)
                Spacer()
                Text("\(timer.completedFocusSessions) completed")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(PomodoroPalette.muted)
            }

            TimerFace(timer: timer, compact: false)

            HStack(spacing: 11) {
                Button { timer.toggle() } label: {
                    Label(timer.isRunning ? "Pause" : "Start focus", systemImage: timer.isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryTimerButton(color: PomodoroPalette.color(for: timer.mode)))

                Button { timer.reset() } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .frame(width: 44, height: 42)
                }
                .buttonStyle(SecondaryTimerButton())
                .help("Reset timer")

                Button { timer.skip() } label: {
                    Image(systemName: "forward.end.fill")
                        .frame(width: 44, height: 42)
                }
                .buttonStyle(SecondaryTimerButton())
                .help("Skip to next phase")
            }

            HStack(spacing: 7) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(index < timer.completedFocusSessions % 4 ? PomodoroPalette.color(for: .focus) : PomodoroPalette.card)
                        .frame(height: 4)
                }
            }
        }
        .padding(24)
        .frame(width: 310, height: 350)
        .background(PomodoroPalette.background)
        .preferredColorScheme(.dark)
    }
}

private struct TimerFace: View {
    @ObservedObject var timer: PomodoroTimer
    let compact: Bool

    var body: some View {
        VStack(spacing: compact ? 7 : 12) {
            ZStack {
                Circle()
                    .stroke(PomodoroPalette.card, lineWidth: compact ? 8 : 10)
                Circle()
                    .trim(from: 0, to: timer.progress)
                    .stroke(PomodoroPalette.color(for: timer.mode), style: StrokeStyle(lineWidth: compact ? 8 : 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.25), value: timer.progress)

                VStack(spacing: 3) {
                    Text(timer.formattedTime)
                        .font(.system(size: compact ? 37 : 43, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .foregroundStyle(PomodoroPalette.text)
                    Text(timer.mode.title.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(PomodoroPalette.color(for: timer.mode))
                }
            }
            .frame(width: compact ? 146 : 190, height: compact ? 146 : 190)

            if !compact {
                Text(timer.isRunning ? "Stay focused. You’re doing great." : "Ready when you are.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PomodoroPalette.muted)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct SettingsView: View {
    @ObservedObject var timer: PomodoroTimer

    var body: some View {
        Form {
            Section("Timer durations") {
                durationRow("Focus", detail: "Work session", value: $timer.focusMinutes)
                durationRow("Short break", detail: "Between focus sessions", value: $timer.shortBreakMinutes)
                durationRow("Long break", detail: "After every four focus sessions", value: $timer.longBreakMinutes)
            }

            Text("Durations are saved automatically. Changes apply to the next timer reset or phase.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 390)
        .onChange(of: timer.focusMinutes) { _, _ in timer.settingsChanged() }
        .onChange(of: timer.shortBreakMinutes) { _, _ in timer.settingsChanged() }
        .onChange(of: timer.longBreakMinutes) { _, _ in timer.settingsChanged() }
    }

    private func durationRow(_ title: String, detail: String, value: Binding<Int>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Stepper(value: value, in: 1...90) {
                Text("\(value.wrappedValue) min")
                    .monospacedDigit()
                    .frame(width: 58, alignment: .trailing)
            }
            .fixedSize()
        }
        .padding(.vertical, 3)
    }
}

private struct PrimaryTimerButton: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .frame(height: 40)
            .background(color.opacity(configuration.isPressed ? 0.72 : 1), in: RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct SecondaryTimerButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(PomodoroPalette.text)
            .background(PomodoroPalette.card.opacity(configuration.isPressed ? 0.65 : 1), in: RoundedRectangle(cornerRadius: 12))
    }
}
