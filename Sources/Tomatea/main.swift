import AppKit
import TomateaCore
import SwiftUI

@main
struct TomateaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var timer: PomodoroTimer
    @StateObject private var shortcutSettings: GlobalShortcutSettings
    @StateObject private var focusMode: FocusModeController
    private let globalHotKey: GlobalHotKey

    init() {
        let timer = PomodoroTimer()
        let shortcutSettings = GlobalShortcutSettings()
        _timer = StateObject(wrappedValue: timer)
        _shortcutSettings = StateObject(wrappedValue: shortcutSettings)
        _focusMode = StateObject(wrappedValue: FocusModeController(timer: timer))
        globalHotKey = GlobalHotKey(settings: shortcutSettings) { timer.startOrReset() }
    }

    var body: some Scene {
        MenuBarExtra {
            PomodoroView(timer: timer, shortcutSettings: shortcutSettings, focusMode: focusMode)
        } label: {
            HStack(spacing: 4) {
                Image(nsImage: MenuBarIcon.image(isRunning: timer.isRunning, session: timer.session))
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
