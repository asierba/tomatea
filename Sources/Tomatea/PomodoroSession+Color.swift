import AppKit
import TomateaCore
import SwiftUI

extension PomodoroSession {
    var color: Color {
        switch self {
        case .focus: Self.tomatoRed
        case .shortBreak: Self.unripeGreen
        case .longBreak: Self.longBreakBlue
        }
    }

    private static let tomatoRed = adaptive(
        light: NSColor(red: 0.80, green: 0.22, blue: 0.13, alpha: 1),
        dark: NSColor(red: 0.96, green: 0.38, blue: 0.27, alpha: 1)
    )

    private static let unripeGreen = adaptive(
        light: NSColor(red: 0.22, green: 0.52, blue: 0.10, alpha: 1),
        dark: NSColor(red: 0.38, green: 0.72, blue: 0.20, alpha: 1)
    )

    private static let longBreakBlue = adaptive(
        light: NSColor(red: 0.18, green: 0.36, blue: 0.72, alpha: 1),
        dark: NSColor(red: 0.36, green: 0.55, blue: 0.90, alpha: 1)
    )

    private static func adaptive(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        })
    }
}
