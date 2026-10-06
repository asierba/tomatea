import AppKit
import Carbon
import PomodoroCore
import SwiftUI

struct ShortcutRecorder: View {
    @Binding var shortcut: GlobalShortcut
    @State private var monitor: Any?

    private var isRecording: Bool { monitor != nil }

    var body: some View {
        Button(isRecording ? "Press keys…" : shortcut.displayName) {
            isRecording ? stopRecording() : startRecording()
        }
        .buttonStyle(.bordered)
        .monospacedDigit()
        .help("Click, then press a shortcut using ⌘, ⌃ or ⌥. Esc cancels.")
        .onDisappear(perform: stopRecording)
    }

    private func startRecording() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == UInt16(kVK_Escape) {
                stopRecording()
            } else if let recorded = GlobalShortcut(
                keyCode: event.keyCode,
                key: event.characters(byApplyingModifiers: []) ?? "",
                modifiers: event.modifierFlags
            ) {
                shortcut = recorded
                stopRecording()
            }
            return nil
        }
    }

    private func stopRecording() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}
