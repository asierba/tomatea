import AppKit

/// The moments the timer announces with a sound. Each has its own bundled
/// sound so they can be told apart without looking at the screen.
public enum TimerSound: Equatable {
    case started
    case focusEnded
    case breakEnded

    var fileURL: URL? {
        Bundle.module.url(forResource: resourceName, withExtension: "wav")
    }

    private var resourceName: String {
        switch self {
        case .started: "FewTicks"
        case .focusEnded: "OldTimerRing"
        case .breakEnded: "DongDing"
        }
    }

    @MainActor
    public static func playBundledSound(_ sound: TimerSound) {
        guard let url = sound.fileURL else { return }
        NSSound(contentsOf: url, byReference: true)?.play()
    }
}
