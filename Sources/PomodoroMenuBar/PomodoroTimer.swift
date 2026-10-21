import Combine
import AppKit
import Foundation

enum PomodoroMode: String, CaseIterable, Identifiable {
    case focus
    case shortBreak
    case longBreak

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus: "Focus"
        case .shortBreak: "Short break"
        case .longBreak: "Long break"
        }
    }

    var symbol: String {
        switch self {
        case .focus: "brain.head.profile"
        case .shortBreak: "cup.and.saucer"
        case .longBreak: "powersleep"
        }
    }

    var colorName: String {
        switch self {
        case .focus: "tomato"
        case .shortBreak: "mint"
        case .longBreak: "blueberry"
        }
    }
}

@MainActor
final class PomodoroTimer: ObservableObject {
    @Published private(set) var mode: PomodoroMode = .focus
    @Published private(set) var remainingSeconds: Int
    @Published private(set) var isRunning = false
    @Published private(set) var completedFocusSessions = 0

    @Published var focusMinutes: Int { didSet { saveSettings() } }
    @Published var shortBreakMinutes: Int { didSet { saveSettings() } }
    @Published var longBreakMinutes: Int { didSet { saveSettings() } }
    @Published var completionSoundEnabled: Bool {
        didSet { defaults.set(completionSoundEnabled, forKey: "completionSoundEnabled") }
    }

    private var endDate: Date?
    private var ticker: Timer?
    private let defaults = UserDefaults.standard

    init() {
        let focus = Self.readMinutes(for: "focusMinutes", default: 25)
        let shortBreak = Self.readMinutes(for: "shortBreakMinutes", default: 5)
        let longBreak = Self.readMinutes(for: "longBreakMinutes", default: 15)
        focusMinutes = focus
        shortBreakMinutes = shortBreak
        longBreakMinutes = longBreak
        completionSoundEnabled = UserDefaults.standard.object(forKey: "completionSoundEnabled") as? Bool ?? true
        remainingSeconds = focus * 60
        restoreTimerState()
    }

    var menuBarTime: String { Self.format(remainingSeconds) }
    var formattedTime: String { Self.format(remainingSeconds) }
    var progress: Double {
        let total = max(1, duration(for: mode) * 60)
        return 1 - Double(remainingSeconds) / Double(total)
    }

    func toggle() {
        isRunning ? pause() : start()
    }

    func start() {
        guard !isRunning else { return }
        if remainingSeconds <= 0 { remainingSeconds = duration(for: mode) * 60 }
        endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        isRunning = true
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        persistTimerState()
    }

    func pause() {
        guard isRunning else { return }
        refresh()
        isRunning = false
        endDate = nil
        ticker?.invalidate()
        ticker = nil
        persistTimerState()
    }

    func reset() {
        isRunning = false
        endDate = nil
        ticker?.invalidate()
        ticker = nil
        remainingSeconds = duration(for: mode) * 60
        persistTimerState()
    }

    func skip() {
        advanceMode()
    }

    func select(_ newMode: PomodoroMode) {
        guard mode != newMode else { return }
        isRunning = false
        endDate = nil
        ticker?.invalidate()
        ticker = nil
        mode = newMode
        remainingSeconds = duration(for: newMode) * 60
        persistTimerState()
    }

    func settingsChanged() {
        guard !isRunning else { return }
        remainingSeconds = duration(for: mode) * 60
        persistTimerState()
    }

    func playCompletionSound() {
        guard completionSoundEnabled else { return }
        NSSound(named: NSSound.Name("Glass"))?.play()
    }

    private func refresh() {
        guard isRunning, let endDate else { return }
        let seconds = Int(ceil(endDate.timeIntervalSinceNow))
        if seconds <= 0 {
            remainingSeconds = 0
            advanceMode(completedNaturally: true)
        } else {
            remainingSeconds = seconds
            persistTimerState()
        }
    }

    private func advanceMode(completedNaturally: Bool = false) {
        ticker?.invalidate()
        ticker = nil
        isRunning = false
        endDate = nil

        if mode == .focus {
            completedFocusSessions += 1
            mode = completedFocusSessions.isMultiple(of: 4) ? .longBreak : .shortBreak
        } else {
            mode = .focus
        }

        if completedNaturally {
            playCompletionSound()
            NotificationCenter.default.post(name: .pomodoroPhaseCompleted, object: mode)
        }

        remainingSeconds = duration(for: mode) * 60
        persistTimerState()
    }

    private func duration(for mode: PomodoroMode) -> Int {
        switch mode {
        case .focus: focusMinutes
        case .shortBreak: shortBreakMinutes
        case .longBreak: longBreakMinutes
        }
    }

    private func saveSettings() {
        defaults.set(focusMinutes, forKey: "focusMinutes")
        defaults.set(shortBreakMinutes, forKey: "shortBreakMinutes")
        defaults.set(longBreakMinutes, forKey: "longBreakMinutes")
        settingsChanged()
    }

    private func persistTimerState() {
        defaults.set(mode.rawValue, forKey: "timerMode")
        defaults.set(remainingSeconds, forKey: "remainingSeconds")
        defaults.set(isRunning, forKey: "timerIsRunning")
        defaults.set(completedFocusSessions, forKey: "completedFocusSessions")
        defaults.set(endDate, forKey: "timerEndDate")
    }

    private func restoreTimerState() {
        if let rawMode = defaults.string(forKey: "timerMode"),
           let restoredMode = PomodoroMode(rawValue: rawMode) {
            mode = restoredMode
        }
        completedFocusSessions = defaults.integer(forKey: "completedFocusSessions")

        if defaults.object(forKey: "timerIsRunning") as? Bool == true,
           let savedEndDate = defaults.object(forKey: "timerEndDate") as? Date {
            endDate = savedEndDate
            isRunning = true
            let left = Int(ceil(savedEndDate.timeIntervalSinceNow))
            if left > 0 {
                remainingSeconds = left
                startTicker()
            } else {
                remainingSeconds = 0
                advanceMode(completedNaturally: true)
            }
        } else if defaults.object(forKey: "remainingSeconds") != nil {
            remainingSeconds = max(0, defaults.integer(forKey: "remainingSeconds"))
        } else {
            remainingSeconds = duration(for: mode) * 60
        }
    }

    private func startTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    private static func readMinutes(for key: String, default value: Int) -> Int {
        let saved = UserDefaults.standard.object(forKey: key) as? Int ?? value
        return min(90, max(1, saved))
    }

    private static func format(_ seconds: Int) -> String {
        String(format: "%02d:%02d", max(0, seconds) / 60, max(0, seconds) % 60)
    }
}

extension Notification.Name {
    static let pomodoroPhaseCompleted = Notification.Name("PomodoroPhaseCompleted")
}
