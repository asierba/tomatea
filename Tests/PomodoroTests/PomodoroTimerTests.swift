import AppKit
import XCTest
@testable import PomodoroCore

@MainActor
final class PomodoroTimerTests: XCTestCase {
    func testFocusAndShortBreakSessionsAlternate() {
        let timer = makeTimer()

        timer.advanceToNextSession()
        XCTAssertEqual(timer.session, .shortBreak)
        XCTAssertEqual(timer.secondsRemaining, 5 * 60)
        XCTAssertEqual(timer.completedPomodoros, 1)

        timer.advanceToNextSession()
        XCTAssertEqual(timer.session, .focus)
        XCTAssertEqual(timer.secondsRemaining, 25 * 60)
    }

    func testFourthPomodoroStartsLongBreakThenResetsCycle() {
        let timer = makeTimer()

        for _ in 0..<4 {
            timer.advanceToNextSession()
            if timer.session == .shortBreak {
                timer.advanceToNextSession()
            }
        }

        XCTAssertEqual(timer.session, .longBreak)
        XCTAssertEqual(timer.secondsRemaining, 15 * 60)
        XCTAssertEqual(timer.completedPomodoros, 4)

        timer.advanceToNextSession()
        XCTAssertEqual(timer.session, .focus)
        XCTAssertEqual(timer.completedPomodoros, 0)
    }

    func testBreaksAutoStartButFocusWaitsForUser() {
        let timer = makeTimer()
        timer.start()

        timer.completeSession()
        XCTAssertEqual(timer.session, .shortBreak)
        XCTAssertTrue(timer.isRunning)

        timer.completeSession()
        XCTAssertEqual(timer.session, .focus)
        XCTAssertFalse(timer.isRunning)
    }

    func testLongBreakAutoStarts() {
        let timer = makeTimer()

        for _ in 0..<3 {
            timer.advanceToNextSession()
            timer.advanceToNextSession()
        }
        timer.completeSession()

        XCTAssertEqual(timer.session, .longBreak)
        XCTAssertTrue(timer.isRunning)
        timer.pause()
    }

    func testFocusAutoStartsAfterBreakWhenStopAfterBreakIsOff() {
        let defaults = makeDefaults()
        let timer = PomodoroTimer(userDefaults: defaults)
        XCTAssertTrue(timer.stopAfterBreak)
        timer.stopAfterBreak = false

        timer.completeSession()
        timer.completeSession()

        XCTAssertEqual(timer.session, .focus)
        XCTAssertTrue(timer.isRunning)
        timer.pause()

        XCTAssertFalse(PomodoroTimer(userDefaults: defaults).stopAfterBreak)
    }

    func testResetReturnsToInitialFocusSession() {
        let timer = makeTimer()
        timer.advanceToNextSession()

        timer.reset()

        XCTAssertEqual(timer.session, .focus)
        XCTAssertEqual(timer.secondsRemaining, 25 * 60)
        XCTAssertEqual(timer.completedPomodoros, 0)
        XCTAssertFalse(timer.isRunning)
    }

    func testStartOrResetStartsWhenStoppedAndResetsWhenRunning() {
        let timer = makeTimer()
        timer.advanceToNextSession()

        timer.startOrReset()
        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.session, .shortBreak)

        timer.startOrReset()
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.session, .focus)
        XCTAssertEqual(timer.completedPomodoros, 0)
    }

    func testConfiguredDurationsApplyToEachSessionAndPersist() {
        let defaults = makeDefaults()
        let timer = PomodoroTimer(userDefaults: defaults)
        let durations = PomodoroDurations(
            focusMinutes: 30,
            shortBreakMinutes: 7,
            longBreakMinutes: 20
        )

        timer.updateDurations(durations)
        XCTAssertEqual(timer.secondsRemaining, 30 * 60)

        timer.advanceToNextSession()
        XCTAssertEqual(timer.secondsRemaining, 7 * 60)
        timer.advanceToNextSession()
        XCTAssertEqual(timer.secondsRemaining, 30 * 60)

        for _ in 0..<3 {
            timer.advanceToNextSession()
            if timer.session == .shortBreak {
                timer.advanceToNextSession()
            }
        }
        XCTAssertEqual(timer.session, .longBreak)
        XCTAssertEqual(timer.secondsRemaining, 20 * 60)

        let reloadedTimer = PomodoroTimer(userDefaults: defaults)
        XCTAssertEqual(reloadedTimer.durations, durations)
    }

    func testDurationsChangedWhileRunningApplyToNextSession() {
        let timer = makeTimer()
        timer.start()

        timer.updateDurations(PomodoroDurations(focusMinutes: 30, shortBreakMinutes: 7, longBreakMinutes: 20))

        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.sessionDuration, 25 * 60)
        XCTAssertEqual(timer.secondsRemaining, 25 * 60)

        timer.advanceToNextSession()
        XCTAssertEqual(timer.sessionDuration, 7 * 60)
        XCTAssertEqual(timer.secondsRemaining, 7 * 60)
        timer.pause()
    }

    func testStartingPlaysStartedSoundOnlyOnce() {
        var sounds: [TimerSound] = []
        let timer = PomodoroTimer(userDefaults: makeDefaults()) { sounds.append($0) }

        timer.start()
        timer.start()
        timer.pause()

        XCTAssertEqual(sounds, [.started])
    }

    func testEachSoundIsDistinct() {
        let names = [TimerSound.started, .focusEnded, .breakEnded].map(\.systemSoundName)
        XCTAssertEqual(Set(names).count, 3)
        for name in names {
            XCTAssertNotNil(NSSound(named: name), "\(name) is not available")
        }
    }

    func testCompletingSessionsPlaysOnlyTheEndSound() {
        var sounds: [TimerSound] = []
        let timer = PomodoroTimer(userDefaults: makeDefaults()) { sounds.append($0) }
        timer.start()
        sounds.removeAll()

        timer.completeSession()
        XCTAssertEqual(sounds, [.focusEnded])
        XCTAssertTrue(timer.isRunning, "the break starts automatically")

        timer.completeSession()
        XCTAssertEqual(sounds, [.focusEnded, .breakEnded])
        XCTAssertFalse(timer.isRunning, "the timer stops after a break by default")
        timer.pause()
    }

    private func makeTimer() -> PomodoroTimer {
        PomodoroTimer(userDefaults: makeDefaults()) { _ in }
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "PomodoroTimerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
