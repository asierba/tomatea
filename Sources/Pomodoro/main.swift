import AppKit
import PomodoroCore
import SwiftUI

@main
struct PomodoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var timer = PomodoroTimer()

    /// Idle while the timer is stopped, otherwise the icon for the running session.
    private var menuBarSymbol: String {
        guard timer.isRunning else { return "timer" }
        return timer.session == .focus ? "brain.head.profile" : "cup.and.saucer"
    }

    var body: some Scene {
        MenuBarExtra {
            PomodoroView(timer: timer)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: menuBarSymbol)
                Text(timer.formattedTime)
                    .monospacedDigit()
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
