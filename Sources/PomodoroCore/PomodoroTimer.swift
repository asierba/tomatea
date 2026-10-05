import AppKit
import Combine
import Foundation

public enum PomodoroSession: Equatable {
    case focus
    case shortBreak
    case longBreak

    public var title: String {
        switch self {
        case .focus: "Focus"
        case .shortBreak: "Short break"
        case .longBreak: "Long break"
        }
    }

    public var duration: Int {
        switch self {
        case .focus: 25 * 60
        case .shortBreak: 5 * 60
        case .longBreak: 15 * 60
        }
    }
}

@MainActor
public final class PomodoroTimer: ObservableObject {
    @Published public private(set) var session: PomodoroSession = .focus
    @Published public private(set) var secondsRemaining = PomodoroSession.focus.duration
    @Published public private(set) var completedPomodoros = 0
    @Published public private(set) var isRunning = false

    private var endDate: Date?
    private var ticker: Timer?

    public var formattedTime: String {
        String(format: "%02d:%02d", secondsRemaining / 60, secondsRemaining % 60)
    }

    public init() {}

    public func start() {
        guard !isRunning else { return }

        isRunning = true
        endDate = Date().addingTimeInterval(TimeInterval(secondsRemaining))
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    public func pause() {
        ticker?.invalidate()
        ticker = nil
        endDate = nil
        isRunning = false
    }

    public func reset() {
        pause()
        session = .focus
        secondsRemaining = PomodoroSession.focus.duration
        completedPomodoros = 0
    }

    private func tick() {
        guard let endDate else { return }

        let timeRemaining = endDate.timeIntervalSinceNow
        guard timeRemaining > 0 else {
            pause()
            NSSound.beep()
            advanceToNextSession()
            return
        }

        secondsRemaining = Int(ceil(timeRemaining))
    }

    func advanceToNextSession() {
        switch session {
        case .focus:
            completedPomodoros += 1
            session = completedPomodoros == 4 ? .longBreak : .shortBreak
        case .shortBreak:
            session = .focus
        case .longBreak:
            completedPomodoros = 0
            session = .focus
        }
        secondsRemaining = session.duration
    }
}
