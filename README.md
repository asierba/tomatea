# Pomodoro

A small macOS menu bar Pomodoro timer. It starts with 25-minute focus sessions,
5-minute short breaks, and a 15-minute break after every fourth focus session.
Session lengths can be changed from the timer's settings and are saved between
launches. Distinct system sounds play when you start the timer, when a focus
session ends, and when a break ends.

## Run

Requires macOS 13 or later and Xcode's Swift toolchain.

```sh
swift run
```

Click the timer in the menu bar to open the controls. Start the current session;
while it runs, the same button becomes Reset, which returns to the beginning of
the cycle (sessions can't be paused). When a focus
session ends, the break starts automatically. When a break ends, the next focus
session is selected and waits for you to start it, unless you turn off
"Stop after break" in the settings, in which case the timer keeps running into
the next focus session. Use the power button (or ⌘Q while the controls are
open) to quit the app.
Use the gear button to configure focus sessions (1–120 minutes), short breaks,
and long breaks (1–60 minutes each). Changes made while a session
is running apply to the next session.
Press ⇧⌘P from any app to start the timer, or to reset it while it is running.
The shortcut can be changed in the settings; it must include ⌘, ⌃ or ⌥.

## Install

```sh
scripts/install.sh
```

Builds a release `Pomodoro.app`, ad-hoc signs it, copies it to `/Applications`.
Re-run to update. To start it at login, add it in
System Settings → General → Login Items.

## Test

```sh
swift test
```
