import AppKit
import TomateaCore

enum MenuBarIcon {
    private static let idle = load("MenuBarIdle")
    private static let focus = load("MenuBarFocus")
    private static let shortBreak = load("MenuBarShortBreak")
    private static let longBreak = load("MenuBarLongBreak")

    static func image(isRunning: Bool, session: PomodoroSession) -> NSImage {
        guard isRunning else { return idle }
        switch session {
        case .focus: return focus
        case .shortBreak: return shortBreak
        case .longBreak: return longBreak
        }
    }

    private static func load(_ name: String) -> NSImage {
        guard let image = Bundle.module.image(forResource: name) else {
            fatalError("Missing menu bar image \(name)")
        }
        image.size = NSSize(width: 18, height: 18)
        return image
    }
}
