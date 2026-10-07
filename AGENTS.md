# CLAUDE.md

macOS 13+ menu bar Pomodoro timer. Swift package (SwiftUI `MenuBarExtra` + AppKit), no Xcode project, no external dependencies.

## Commands

```sh
swift build
swift run                     # launches the menu bar app
swift test
swift test --filter PomodoroTimerTests/testBreaksAutoStartButFocusWaitsForUser
```

Requires macOS and the Xcode Swift toolchain. If a check can't run, say so — don't report it as passing.

## Gotchas

- `TomateaCore` holds all timer logic and has no UI; the `Tomatea` target is SwiftUI/AppKit only.
- Countdown uses a wall-clock `endDate` + 1s `Timer` ticker, not a decrementing counter.
- `sessionDuration` is fixed when a session begins; `updateDurations` only re-applies to the current session if it is untouched (not running).
- Tests inject a unique `UserDefaults` suite and a no-op sound closure via `PomodoroTimer.init(userDefaults:playSound:)`, and drive the `internal` `completeSession()` / `advanceToNextSession()` via `@testable import`.
- Menu bar PNGs in `Sources/Tomatea/Resources` and `Assets/AppIcon.icns` are generated from `Assets/AppIcon.png` by `scripts/make-menubar-icons.swift` and `scripts/make-icon.swift`; regenerate, don't hand-edit.
- `scripts/install.sh` must copy the SwiftPM resource bundle into the `.app`, or `Bundle.module` crashes at launch.

## Product contract (keep consistent with README.md)

- 25 min focus, 5 min short break, 15 min long break after every 4th focus.
- Focus completes → break starts automatically.
- Break completes → next focus selected; auto-starts only if "Stop after break" is off (default on).
- Main button / global shortcut: Start when stopped; Stop during focus (stopped focus, cycle count kept); Skip break during a break (next focus starts immediately).
- Reset → stopped focus session, cycle count 0.
- Update tests for any timer behaviour change. UI/menu bar changes aren't covered by tests — verify in the running app when possible.
