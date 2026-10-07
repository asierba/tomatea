import AppKit
import XCTest
@testable import TomateaCore

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
        timer.reset()
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
        timer.reset()

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

    func testPrimaryActionStartsWhenStopped() {
        let timer = makeTimer()

        XCTAssertEqual(timer.primaryAction, .start)
        timer.performPrimaryAction()

        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.session, .focus)
        timer.reset()
    }

    func testPrimaryActionStopsFocusAndKeepsCycle() {
        let timer = makeTimer()
        timer.advanceToNextSession()
        timer.advanceToNextSession()
        timer.start()

        XCTAssertEqual(timer.primaryAction, .stop)
        timer.performPrimaryAction()

        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.session, .focus)
        XCTAssertEqual(timer.secondsRemaining, 25 * 60)
        XCTAssertEqual(timer.completedPomodoros, 1)
    }

    func testPrimaryActionSkipsBreakAndStartsFocus() {
        let timer = makeTimer()
        timer.start()
        timer.completeSession()

        XCTAssertEqual(timer.primaryAction, .skipBreak)
        timer.performPrimaryAction()

        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.session, .focus)
        XCTAssertEqual(timer.secondsRemaining, 25 * 60)
        XCTAssertEqual(timer.completedPomodoros, 1)
        timer.reset()
    }

    func testSkippingLongBreakStartsNewCycle() {
        let timer = makeTimer()
        for _ in 0..<3 {
            timer.advanceToNextSession()
            timer.advanceToNextSession()
        }
        timer.completeSession()

        timer.skipBreak()

        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.session, .focus)
        XCTAssertEqual(timer.completedPomodoros, 0)
        timer.reset()
    }

    func testHasProgressWhenRunningOrCycleStarted() {
        let timer = makeTimer()
        XCTAssertFalse(timer.hasProgress)

        timer.start()
        XCTAssertTrue(timer.hasProgress)

        timer.stop()
        XCTAssertFalse(timer.hasProgress)

        timer.advanceToNextSession()
        XCTAssertTrue(timer.hasProgress)
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
        timer.reset()
    }

    func testStartingPlaysStartedSoundOnlyOnce() {
        var sounds: [TimerSound] = []
        let timer = PomodoroTimer(userDefaults: makeDefaults()) { sounds.append($0) }

        timer.start()
        timer.start()
        timer.reset()

        XCTAssertEqual(sounds, [.started])
    }

    func testEachSoundIsDistinct() {
        let urls = [TimerSound.started, .focusEnded, .breakEnded].map(\.fileURL)
        XCTAssertEqual(Set(urls).count, 3)
        for url in urls {
            XCTAssertNotNil(url.flatMap { NSSound(contentsOf: $0, byReference: true) }, "\(String(describing: url)) is not playable")
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
        timer.reset()
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
