import XCTest
@testable import PomodoroCore

@MainActor
final class PomodoroTimerTests: XCTestCase {
    func testFocusAndShortBreakSessionsAlternate() {
        let timer = PomodoroTimer()

        timer.advanceToNextSession()
        XCTAssertEqual(timer.session, .shortBreak)
        XCTAssertEqual(timer.secondsRemaining, 5 * 60)
        XCTAssertEqual(timer.completedPomodoros, 1)

        timer.advanceToNextSession()
        XCTAssertEqual(timer.session, .focus)
        XCTAssertEqual(timer.secondsRemaining, 25 * 60)
    }

    func testFourthPomodoroStartsLongBreakThenResetsCycle() {
        let timer = PomodoroTimer()

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

    func testResetReturnsToInitialFocusSession() {
        let timer = PomodoroTimer()
        timer.advanceToNextSession()

        timer.reset()

        XCTAssertEqual(timer.session, .focus)
        XCTAssertEqual(timer.secondsRemaining, 25 * 60)
        XCTAssertEqual(timer.completedPomodoros, 0)
        XCTAssertFalse(timer.isRunning)
    }
}
