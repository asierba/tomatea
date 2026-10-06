import AppKit
import TomateaCore
import SwiftUI

@main
struct TomateaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var timer: PomodoroTimer
    @StateObject private var shortcutSettings: GlobalShortcutSettings
    private let globalHotKey: GlobalHotKey

    init() {
        let timer = PomodoroTimer()
        let shortcutSettings = GlobalShortcutSettings()
        _timer = StateObject(wrappedValue: timer)
        _shortcutSettings = StateObject(wrappedValue: shortcutSettings)
        globalHotKey = GlobalHotKey(settings: shortcutSettings) { timer.startOrReset() }
    }

    /// Idle while the timer is stopped, otherwise the icon for the running session.
    private var menuBarSymbol: String {
        guard timer.isRunning else { return "timer" }
        return timer.session == .focus ? "brain.head.profile" : "cup.and.saucer"
    }

    var body: some Scene {
        MenuBarExtra {
            PomodoroView(timer: timer, shortcutSettings: shortcutSettings)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: menuBarSymbol)
                if timer.isRunning {
                    Text(timer.formattedTime)
                        .monospacedDigit()
                }
            }
            .help("\(timer.session.title) · \(timer.formattedTime)")
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
