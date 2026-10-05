import AppKit
import PomodoroCore
import SwiftUI

@main
struct PomodoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var timer = PomodoroTimer()

    var body: some Scene {
        MenuBarExtra {
            PomodoroView(timer: timer)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "timer")
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
