import AppKit
import TomateaCore
import SwiftUI

extension PomodoroSession {
    var color: Color {
        switch self {
        case .focus: Self.focusBlue
        case .shortBreak, .longBreak: .teal
        }
    }

    private static let focusBlue = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor(red: 0.49, green: 0.61, blue: 1.0, alpha: 1)
            : NSColor(red: 0.12, green: 0.25, blue: 0.6, alpha: 1)
    })
}
