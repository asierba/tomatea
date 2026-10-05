import AppKit
import Combine
import PomodoroCore
import SwiftUI

@main
struct PomodoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private let timer = PomodoroTimer()
    private var timerObservation: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "timer",
                accessibilityDescription: "Pomodoro timer"
            )
            button.imagePosition = .imageLeading
            button.target = self
            button.action = #selector(togglePopover(_:))
        }

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 300, height: 330)
        popover.contentViewController = NSHostingController(
            rootView: PomodoroView(timer: timer)
        )

        timerObservation = timer.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async {
                self?.updateStatusItem()
            }
        }
        updateStatusItem()
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func updateStatusItem() {
        statusItem.button?.title = timer.formattedTime
        statusItem.button?.toolTip = "\(timer.session.title) · \(timer.formattedTime)"
    }
}
