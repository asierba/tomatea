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
}

public struct PomodoroDurations: Equatable {
    public var focusMinutes: Int
    public var shortBreakMinutes: Int
    public var longBreakMinutes: Int

    public static let standard = PomodoroDurations(
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15
    )

    public init(focusMinutes: Int, shortBreakMinutes: Int, longBreakMinutes: Int) {
        self.focusMinutes = min(max(focusMinutes, 1), 120)
        self.shortBreakMinutes = min(max(shortBreakMinutes, 1), 60)
        self.longBreakMinutes = min(max(longBreakMinutes, 1), 60)
    }

    public var focusSeconds: Int { focusMinutes * 60 }
    public var shortBreakSeconds: Int { shortBreakMinutes * 60 }
    public var longBreakSeconds: Int { longBreakMinutes * 60 }

    fileprivate func duration(for session: PomodoroSession) -> Int {
        switch session {
        case .focus: focusSeconds
        case .shortBreak: shortBreakSeconds
        case .longBreak: longBreakSeconds
        }
    }

    fileprivate static func load(from defaults: UserDefaults) -> PomodoroDurations {
        let standard = PomodoroDurations.standard
        return PomodoroDurations(
            focusMinutes: defaults.object(forKey: "Pomodoro.focusMinutes") as? Int ?? standard.focusMinutes,
            shortBreakMinutes: defaults.object(forKey: "Pomodoro.shortBreakMinutes") as? Int ?? standard.shortBreakMinutes,
            longBreakMinutes: defaults.object(forKey: "Pomodoro.longBreakMinutes") as? Int ?? standard.longBreakMinutes
        )
    }

    fileprivate func save(to defaults: UserDefaults) {
        defaults.set(focusMinutes, forKey: "Pomodoro.focusMinutes")
        defaults.set(shortBreakMinutes, forKey: "Pomodoro.shortBreakMinutes")
        defaults.set(longBreakMinutes, forKey: "Pomodoro.longBreakMinutes")
    }
}

@MainActor
public final class PomodoroTimer: ObservableObject {
    @Published public private(set) var session: PomodoroSession = .focus
    @Published public private(set) var secondsRemaining = PomodoroDurations.standard.focusSeconds
    @Published public private(set) var completedPomodoros = 0
    @Published public private(set) var isRunning = false
    @Published public private(set) var durations: PomodoroDurations

    private let userDefaults: UserDefaults

    private var endDate: Date?
    private var ticker: Timer?

    public var sessionDuration: Int {
        durations.duration(for: session)
    }

    public var formattedTime: String {
        String(format: "%02d:%02d", secondsRemaining / 60, secondsRemaining % 60)
    }

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        durations = PomodoroDurations.load(from: userDefaults)
        secondsRemaining = durations.focusSeconds
    }

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
        secondsRemaining = sessionDuration
        completedPomodoros = 0
    }

    public func updateDurations(_ durations: PomodoroDurations) {
        guard !isRunning else { return }

        let validatedDurations = PomodoroDurations(
            focusMinutes: durations.focusMinutes,
            shortBreakMinutes: durations.shortBreakMinutes,
            longBreakMinutes: durations.longBreakMinutes
        )
        self.durations = validatedDurations
        validatedDurations.save(to: userDefaults)
        secondsRemaining = sessionDuration
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
        secondsRemaining = sessionDuration
    }
}
