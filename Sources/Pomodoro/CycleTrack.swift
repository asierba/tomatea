import PomodoroCore
import SwiftUI

struct CycleTrack: View {
    let session: PomodoroSession
    let completedPomodoros: Int
    let progress: Double

    private static let segments: [PomodoroSession] = [
        .focus, .shortBreak, .focus, .shortBreak, .focus, .shortBreak, .focus, .longBreak,
    ]
    private static let spacing: CGFloat = 3

    private var currentIndex: Int {
        switch session {
        case .focus: completedPomodoros * 2
        case .shortBreak: completedPomodoros * 2 - 1
        case .longBreak: Self.segments.count - 1
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let totalWeight = Self.segments.map(\.trackWeight).reduce(0, +)
            let availableWidth = geometry.size.width - Self.spacing * CGFloat(Self.segments.count - 1)
            HStack(spacing: Self.spacing) {
                ForEach(Self.segments.indices, id: \.self) { index in
                    segment(at: index)
                        .frame(width: availableWidth * Self.segments[index].trackWeight / totalWeight)
                }
            }
        }
        .frame(height: 6)
        .accessibilityElement()
        .accessibilityLabel("\(completedPomodoros) of 4 pomodoros done")
    }

    private func segment(at index: Int) -> some View {
        let kind = Self.segments[index]
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
