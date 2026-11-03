import TomateaCore
import SwiftUI

struct CycleTrack: View {
    let session: PomodoroSession
    let completedPomodoros: Int
    let cycleLength: Int
    let isLongBreakSwapped: Bool
    let progress: Double

    private static let spacing: CGFloat = 3

    private var segments: [PomodoroSession] {
        let finalBreak: PomodoroSession = isLongBreakSwapped ? .shortBreak : .longBreak
        return (0..<cycleLength).flatMap { index in
            [.focus, index == cycleLength - 1 ? finalBreak : .shortBreak]
        }
    }

    private var currentIndex: Int {
        switch session {
        case .focus: completedPomodoros * 2
        case .shortBreak: completedPomodoros * 2 - 1
        case .longBreak: segments.count - 1
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let segments = segments
            let totalWeight = segments.map(\.trackWeight).reduce(0, +)
            let availableWidth = geometry.size.width - Self.spacing * CGFloat(segments.count - 1)
            HStack(spacing: Self.spacing) {
                ForEach(segments.indices, id: \.self) { index in
                    segment(segments[index], at: index)
                        .frame(width: availableWidth * segments[index].trackWeight / totalWeight)
                }
            }
        }
        .frame(height: 6)
        .accessibilityElement()
        .accessibilityLabel("\(completedPomodoros) of \(cycleLength) pomodoros done")
    }

    private func segment(_ kind: PomodoroSession, at index: Int) -> some View {
        let filled = index < currentIndex ? 1 : index == currentIndex ? progress : 0
        return Capsule()
            .fill(.quaternary)
            .overlay(alignment: .leading) {
                GeometryReader { geometry in
                    Capsule()
                        .fill(kind.color)
                        .frame(width: geometry.size.width * filled)
                }
            }
            .opacity(index < currentIndex ? 0.45 : 1)
    }
}

private extension PomodoroSession {
    var trackWeight: CGFloat {
        switch self {
        case .focus: 3
        case .shortBreak: 1
        case .longBreak: 2
        }
    }
}
