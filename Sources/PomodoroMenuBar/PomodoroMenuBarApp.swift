import AppKit
import SwiftUI
import UserNotifications

@main
struct PomodoroMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var timer = PomodoroTimer()

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanel(timer: timer)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: timer.mode.symbol)
                Text(timer.menuBarTime)
                    .monospacedDigit()
            }
        }
        .menuBarExtraStyle(.window)

        Window("Pomodoro", id: "floating-timer") {
            FloatingTimerView(timer: timer)
                .background(WindowConfigurator())
        }
        .defaultSize(width: 310, height: 370)
        .windowResizability(.contentSize)

        Window("Pomodoro Settings", id: "settings") {
            SettingsView(timer: timer)
        }
        .defaultSize(width: 500, height: 430)
        .windowResizability(.contentSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(phaseCompleted(_:)),
            name: .pomodoroPhaseCompleted,
            object: nil
        )
    }

    @objc private func phaseCompleted(_ notification: Notification) {
        let nextMode = (notification.object as? PomodoroMode)?.title.lowercased() ?? "the next phase"
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Pomodoro complete"
            content.body = "Time for \(nextMode)."
            content.sound = .default
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            center.add(request)
        }
    }
}

private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { configure(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { configure(nsView.window) }
    }

    private func configure(_ window: NSWindow?) {
        guard let window else { return }
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
    }
}
