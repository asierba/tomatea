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

public enum PrimaryAction: Equatable {
    case start
    case stop
    case skipBreak
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
            focusMinutes: defaults.object(forKey: "Tomatea.focusMinutes") as? Int ?? standard.focusMinutes,
            shortBreakMinutes: defaults.object(forKey: "Tomatea.shortBreakMinutes") as? Int ?? standard.shortBreakMinutes,
            longBreakMinutes: defaults.object(forKey: "Tomatea.longBreakMinutes") as? Int ?? standard.longBreakMinutes
        )
    }

    fileprivate func save(to defaults: UserDefaults) {
        defaults.set(focusMinutes, forKey: "Tomatea.focusMinutes")
        defaults.set(shortBreakMinutes, forKey: "Tomatea.shortBreakMinutes")
        defaults.set(longBreakMinutes, forKey: "Tomatea.longBreakMinutes")
    }
}

@MainActor
public final class PomodoroTimer: ObservableObject {
    @Published public private(set) var session: PomodoroSession = .focus
    @Published public private(set) var secondsRemaining = PomodoroDurations.standard.focusSeconds
    @Published public private(set) var completedPomodoros = 0
    @Published public private(set) var isRunning = false
    @Published public private(set) var durations: PomodoroDurations
    /// Length of the current session. Fixed when the session begins, so changing
    /// `durations` only affects sessions that start afterwards.
    @Published public private(set) var sessionDuration: Int
    /// When true (the default), the timer stops after a break instead of
    /// continuing into the next focus session.
    @Published public var stopAfterBreak: Bool {
        didSet { userDefaults.set(stopAfterBreak, forKey: Self.stopAfterBreakKey) }
    }

    private static let stopAfterBreakKey = "Tomatea.stopAfterBreak"
    private let userDefaults: UserDefaults
    private let playSound: @MainActor (TimerSound) -> Void

    private var endDate: Date?
    private var ticker: Timer?

    public var formattedTime: String {
        String(format: "%02d:%02d", secondsRemaining / 60, secondsRemaining % 60)
    }

    public init(
        userDefaults: UserDefaults = .standard,
        playSound: @escaping @MainActor (TimerSound) -> Void = TimerSound.playBundledSound
    ) {
        self.userDefaults = userDefaults
        self.playSound = playSound
        let durations = PomodoroDurations.load(from: userDefaults)
        self.durations = durations
        sessionDuration = durations.focusSeconds
        stopAfterBreak = userDefaults.object(forKey: Self.stopAfterBreakKey) as? Bool ?? true
        secondsRemaining = durations.focusSeconds
    }

    public func start() {
        guard !isRunning else { return }

        playSound(.started)
        startCountdown()
    }

    private func startCountdown() {
        isRunning = true
        endDate = Date().addingTimeInterval(TimeInterval(secondsRemaining))
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    private func stopCountdown() {
        ticker?.invalidate()
        ticker = nil
        endDate = nil
        isRunning = false
    }

    public var primaryAction: PrimaryAction {
        guard isRunning else { return .start }
        return session == .focus ? .stop : .skipBreak
    }

    public var hasProgress: Bool {
        isRunning || completedPomodoros > 0
    }

    public func performPrimaryAction() {
        switch primaryAction {
        case .start: start()
        case .stop: stop()
        case .skipBreak: skipBreak()
        }
    }

    public func stop() {
        stopCountdown()
        beginSession()
    }

    public func skipBreak() {
        guard session != .focus else { return }

        stopCountdown()
        advanceToNextSession()
        start()
    }

    public func reset() {
        stopCountdown()
        session = .focus
        beginSession()
        completedPomodoros = 0
    }

    /// Saves new session lengths. They apply to sessions that start afterwards;
    /// a running session keeps its length.
    public func updateDurations(_ durations: PomodoroDurations) {
        let sessionIsUntouched = !isRunning

        let validatedDurations = PomodoroDurations(
            focusMinutes: durations.focusMinutes,
            shortBreakMinutes: durations.shortBreakMinutes,
            longBreakMinutes: durations.longBreakMinutes
        )
        self.durations = validatedDurations
        validatedDurations.save(to: userDefaults)
        if sessionIsUntouched {
            beginSession()
        }
    }

    private func beginSession() {
        sessionDuration = durations.duration(for: session)
        secondsRemaining = sessionDuration
    }

    private func tick() {
        guard let endDate else { return }

        let timeRemaining = endDate.timeIntervalSinceNow
        guard timeRemaining > 0 else {
            completeSession()
            return
        }

        secondsRemaining = Int(ceil(timeRemaining))
    }

    /// Ends the running session and moves to the next one. Breaks start
    /// automatically; a new focus session starts only if `stopAfterBreak` is off.
    /// The end-of-session sound is the only cue, even when the next session
    /// starts by itself.
    func completeSession() {
        stopCountdown()
        playSound(session == .focus ? .focusEnded : .breakEnded)
        advanceToNextSession()
        if session != .focus || !stopAfterBreak {
            startCountdown()
        }
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
        beginSession()
    }
}
