import AppKit
import Combine

public struct GlobalShortcut: Equatable, Codable {
    public let keyCode: UInt16
    public let key: String
    private let modifierFlags: UInt

    private static let requiredModifiers: NSEvent.ModifierFlags = [.command, .control, .option]
    private static let supportedModifiers: NSEvent.ModifierFlags = [.command, .control, .option, .shift]

    public static let standard = GlobalShortcut(keyCode: 35, key: "P", modifiers: [.command, .shift])!

    /// Fails unless the shortcut uses ⌘, ⌃ or ⌥, so it cannot swallow ordinary typing.
    public init?(keyCode: UInt16, key: String, modifiers: NSEvent.ModifierFlags) {
        let modifiers = modifiers.intersection(Self.supportedModifiers)
        guard !modifiers.isDisjoint(with: Self.requiredModifiers), !key.isEmpty else { return nil }

        self.keyCode = keyCode
        self.key = key.uppercased()
        modifierFlags = modifiers.rawValue
    }

    public var modifiers: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifierFlags)
    }

    public var displayName: String {
        let symbols: [(NSEvent.ModifierFlags, String)] = [
            (.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")
        ]
        return symbols.filter { modifiers.contains($0.0) }.map(\.1).joined() + key
    }
}

@MainActor
public final class GlobalShortcutSettings: ObservableObject {
    @Published public var shortcut: GlobalShortcut {
        didSet { save() }
    }

    private static let key = "Pomodoro.globalShortcut"
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        shortcut = userDefaults.data(forKey: Self.key)
            .flatMap { try? JSONDecoder().decode(GlobalShortcut.self, from: $0) }
            ?? .standard
    }

    private func save() {
        userDefaults.set(try? JSONEncoder().encode(shortcut), forKey: Self.key)
    }
}
