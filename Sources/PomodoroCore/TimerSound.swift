import AppKit

/// The moments the timer announces with a sound. Each has its own macOS
/// system sound so they can be told apart without looking at the screen.
public enum TimerSound: Equatable {
    case started
    case focusEnded
    case breakEnded

    var systemSoundName: NSSound.Name {
        switch self {
        case .started: "Ping"
        case .focusEnded: "Glass"
        case .breakEnded: "Hero"
        }
    }

    @MainActor
    public static func playSystemSound(_ sound: TimerSound) {
        NSSound(named: sound.systemSoundName)?.play()
    }
}
