import PomodoroCore
import SwiftUI

struct PomodoroView: View {
    @ObservedObject var timer: PomodoroTimer

    private var progress: Double {
        Double(timer.session.duration - timer.secondsRemaining) / Double(timer.session.duration)
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Image(systemName: timer.session == .focus ? "brain.head.profile" : "cup.and.saucer")
                    .foregroundStyle(sessionColor)
                Text(timer.session.title)
                    .font(.headline)
                Spacer()
                Text("\(timer.completedPomodoros) of 4")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Text(timer.formattedTime)
                .font(.system(size: 54, weight: .light, design: .rounded).monospacedDigit())
                .contentTransition(.numericText())
                .accessibilityLabel("\(timer.session.title), \(timer.formattedTime) remaining")

            ProgressView(value: progress)
                .tint(sessionColor)

            Text(timer.isRunning ? "Stay focused" : "Ready when you are")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button {
                    timer.isRunning ? timer.pause() : timer.start()
                } label: {
                    Label(timer.isRunning ? "Pause" : "Start", systemImage: timer.isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(sessionColor)
                .keyboardShortcut(.defaultAction)

                Button("Reset", systemImage: "arrow.counterclockwise") {
                    timer.reset()
                }
                .buttonStyle(.bordered)
                .labelStyle(.iconOnly)
                .help("Reset the timer")
            }
        }
        .padding(22)
        .frame(width: 300, height: 330)
    }

    private var sessionColor: Color {
        timer.session == .focus ? .orange : .teal
    }
}
