import AppKit
import PomodoroCore
import SwiftUI

struct PomodoroView: View {
    @ObservedObject var timer: PomodoroTimer
    @State private var showingSettings = false

    private var progress: Double {
        Double(timer.sessionDuration - timer.secondsRemaining) / Double(timer.sessionDuration)
    }

    var body: some View {
        Group {
            if showingSettings {
                settingsView
            } else {
                timerView
            }
        }
        .padding(22)
        .frame(width: 300, height: 330)
    }

    private var timerView: some View {
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
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .help("Configure session lengths")
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

                Button("Quit", systemImage: "power") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
                .labelStyle(.iconOnly)
                .keyboardShortcut("q")
                .help("Quit Pomodoro")
            }
        }
    }

    private var settingsView: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    showingSettings = false
                } label: {
                    Label("Timer", systemImage: "chevron.left")
                }
                .buttonStyle(.plain)

                Spacer()
                Text("Settings")
                    .font(.headline)
                Spacer()
            }

            durationStepper(
                "Focus",
                value: durationBinding(\.focusMinutes),
                range: 1...120
            )
            durationStepper(
                "Short break",
                value: durationBinding(\.shortBreakMinutes),
                range: 1...60
            )
            durationStepper(
                "Long break",
                value: durationBinding(\.longBreakMinutes),
                range: 1...60
            )

            Toggle("Stop after break", isOn: $timer.stopAfterBreak)
                .help("When off, the next focus session starts automatically after a break")

            if timer.isRunning {
                Text("Changes apply to the next session.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button("Restore defaults") {
                timer.updateDurations(.standard)
            }
            .buttonStyle(.bordered)
        }
    }

    private func durationStepper(
        _ title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>
    ) -> some View {
        Stepper(value: value, in: range) {
            HStack {
                Text(title)
                Spacer()
                TextField(title, value: clamped(value, to: range), format: .number)
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .frame(width: 52)
                Text("min")
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Typed values can fall outside the range the stepper enforces, so clamp them on write.
    private func clamped(_ value: Binding<Int>, to range: ClosedRange<Int>) -> Binding<Int> {
        Binding(
            get: { value.wrappedValue },
            set: { value.wrappedValue = min(max($0, range.lowerBound), range.upperBound) }
        )
    }

    private func durationBinding(_ keyPath: WritableKeyPath<PomodoroDurations, Int>) -> Binding<Int> {
        Binding(
            get: { timer.durations[keyPath: keyPath] },
            set: { newValue in
                var updated = timer.durations
                updated[keyPath: keyPath] = newValue
                timer.updateDurations(updated)
            }
        )
    }

    private var sessionColor: Color {
        timer.session == .focus ? .orange : .teal
    }
}
