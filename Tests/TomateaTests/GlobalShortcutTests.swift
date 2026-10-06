import AppKit
import XCTest
@testable import TomateaCore

@MainActor
final class GlobalShortcutTests: XCTestCase {
    func testDefaultsToCommandShiftP() {
        let settings = GlobalShortcutSettings(userDefaults: makeDefaults())

        XCTAssertEqual(settings.shortcut, .standard)
        XCTAssertEqual(settings.shortcut.displayName, "⇧⌘P")
    }

    func testChangedShortcutPersists() {
        let defaults = makeDefaults()
        let shortcut = GlobalShortcut(keyCode: 17, key: "t", modifiers: [.control, .option])!

        GlobalShortcutSettings(userDefaults: defaults).shortcut = shortcut

        XCTAssertEqual(GlobalShortcutSettings(userDefaults: defaults).shortcut, shortcut)
        XCTAssertEqual(shortcut.displayName, "⌃⌥T")
    }

    func testRejectsShortcutsWithoutCommandControlOrOption() {
        XCTAssertNil(GlobalShortcut(keyCode: 35, key: "p", modifiers: []))
        XCTAssertNil(GlobalShortcut(keyCode: 35, key: "p", modifiers: [.shift]))
    }

    func testIgnoresUnsupportedModifiers() {
        let shortcut = GlobalShortcut(keyCode: 35, key: "p", modifiers: [.command, .capsLock, .function])

        XCTAssertEqual(shortcut?.modifiers, [.command])
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "GlobalShortcutTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
