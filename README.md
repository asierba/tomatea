# Pomodoro

A small macOS menu bar Pomodoro timer. It runs 25-minute focus sessions, 5-minute
short breaks, and a 15-minute break after every fourth focus session. A system
sound plays when a session ends.

## Run

Requires macOS 13 or later and Xcode's Swift toolchain.

```sh
swift run
```

Click the timer in the menu bar to open the controls. Start or pause the current
session, and use Reset to return to the beginning of the cycle. When a session
ends, the next session is selected and waits for you to start it.

## Test

```sh
swift test
```
