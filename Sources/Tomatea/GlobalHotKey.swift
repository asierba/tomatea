import AppKit
import Carbon
import Combine
import TomateaCore

/// Carbon hot keys work system-wide without the Accessibility permission an event tap would need.
@MainActor
final class GlobalHotKey {
    private static let signature: OSType = 0x504D_4452

    private let action: @MainActor () -> Void
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private var subscription: AnyCancellable?

    init(settings: GlobalShortcutSettings, action: @escaping @MainActor () -> Void) {
        self.action = action
        installHandler()
        subscription = settings.$shortcut.sink { [weak self] in self?.register($0) }
    }

    private func register(_ shortcut: GlobalShortcut) {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRef = nil
        RegisterEventHotKey(
            UInt32(shortcut.keyCode),
            carbonModifiers(shortcut.modifiers),
            EventHotKeyID(signature: Self.signature, id: 1),
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    private func installHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
                MainActor.assumeIsolated { hotKey.action() }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )
    }

    private func carbonModifiers(_ modifiers: NSEvent.ModifierFlags) -> UInt32 {
        let mapping: [(NSEvent.ModifierFlags, Int)] = [
            (.command, cmdKey), (.shift, shiftKey), (.option, optionKey), (.control, controlKey)
        ]
        return mapping
            .filter { modifiers.contains($0.0) }
            .reduce(0) { $0 | UInt32($1.1) }
    }
}
