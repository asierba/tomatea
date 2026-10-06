import AppKit
import Combine
import TomateaCore

/// macOS has no public API to toggle Focus, so this runs user-created shortcuts that do it.
@MainActor
final class FocusModeController: ObservableObject {
    static let onShortcut = "Tomatea Focus On"
    static let offShortcut = "Tomatea Focus Off"
    private static let enabledKey = "Tomatea.focusModeEnabled"

    @Published private(set) var isEnabled: Bool {
        didSet {
            userDefaults.set(isEnabled, forKey: Self.enabledKey)
            apply()
        }
    }
    @Published private(set) var errorMessage: String?
    @Published private(set) var missingShortcuts: [String] = []

    private let userDefaults: UserDefaults
    private let queue = DispatchQueue(label: "Tomatea.FocusMode")
    private var isFocusing = false
    private var isFocusOn = false
    private var subscriptions: Set<AnyCancellable> = []

    init(timer: PomodoroTimer, userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        isEnabled = userDefaults.bool(forKey: Self.enabledKey)

        timer.$isRunning.combineLatest(timer.$session)
            .map { isRunning, session in isRunning && session == .focus }
            .removeDuplicates()
            .sink { [weak self] isFocusing in
                self?.isFocusing = isFocusing
                self?.apply()
            }
            .store(in: &subscriptions)

        NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
            .sink { [weak self] _ in self?.turnOffBeforeQuitting() }
            .store(in: &subscriptions)
    }

    func setEnabled(_ enabled: Bool) {
        if enabled {
            checkShortcuts()
            guard missingShortcuts.isEmpty else { return }
        } else {
            missingShortcuts = []
        }
        isEnabled = enabled
    }

    func refresh() {
        if isEnabled {
            checkShortcuts()
        } else {
            missingShortcuts = []
        }
    }

    private func checkShortcuts() {
        let existing = (try? ShortcutRunner.existingNames()) ?? []
        missingShortcuts = [Self.onShortcut, Self.offShortcut].filter { !existing.contains($0) }
    }

    private func apply() {
        let shouldBeOn = isEnabled && isFocusing
        guard shouldBeOn != isFocusOn else { return }

        isFocusOn = shouldBeOn
        let name = shouldBeOn ? Self.onShortcut : Self.offShortcut
        queue.async { [weak self] in
            let message: String?
            do {
                try ShortcutRunner.run(name)
                message = nil
            } catch {
                message = error.localizedDescription
            }
            Task { @MainActor in self?.errorMessage = message }
        }
    }

    private func turnOffBeforeQuitting() {
        guard isFocusOn else { return }

        isFocusOn = false
        let name = Self.offShortcut
        queue.sync { try? ShortcutRunner.run(name) }
    }
}
