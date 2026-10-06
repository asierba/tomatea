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

## Architecture

- `PomodoroCore` (library): all timer logic, testable without UI.
  - `PomodoroTimer`: `@MainActor ObservableObject`, single source of truth. Countdown uses a wall-clock `endDate` + 1s `Timer` ticker (not decrementing a counter).
  - `PomodoroDurations`: clamps values (focus 1–120, breaks 1–60) and persists to `UserDefaults` under `Pomodoro.*` keys.
  - `sessionDuration` is fixed when a session begins; `updateDurations` only re-applies to the current session if it is untouched (not running, not partially elapsed).
  - `TimerSound`: maps events to macOS system sounds.
- `Pomodoro` (executable): `main.swift` (app entry, menu bar label/icon, `.accessory` activation policy) and `PomodoroView` (timer + settings screens toggled in one popover).
- Dependencies injected via `PomodoroTimer.init(userDefaults:playSound:)`. Tests use a unique `UserDefaults` suite and a no-op sound closure; `completeSession()` / `advanceToNextSession()` are `internal` and driven directly via `@testable import`.

## Product contract (keep consistent with README.md)

- 25 min focus, 5 min short break, 15 min long break after every 4th focus.
- Focus completes → break starts automatically.
- Break completes → next focus selected; auto-starts only if "Stop after break" is off (default on).
- Reset → stopped focus session, cycle count 0.
- Update tests for any timer behaviour change. UI/menu bar changes aren't covered by tests — verify in the running app when possible.
