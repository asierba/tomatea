import AppKit
import TomateaCore
import SwiftUI

struct PomodoroView: View {
    @ObservedObject var timer: PomodoroTimer
    @ObservedObject var shortcutSettings: GlobalShortcutSettings
    @State private var showingSettings = false
    @Environment(\.colorScheme) private var colorScheme

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
        .padding(16)
        .frame(width: 300)
        .background(colorScheme == .light ? Color.white : nil)
        .background(WindowFitter(contentID: showingSettings))
    }

    private var timerView: some View {
        VStack(spacing: 16) {
            HStack {
                Text(timer.formattedTime)
                    .font(.system(size: 46, weight: .light, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText())
                    .accessibilityLabel("\(timer.session.title), \(timer.formattedTime) remaining")
                Spacer()
                Text(timer.session.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(timer.session.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(timer.session.color.opacity(0.14), in: Capsule())
            }

            VStack(spacing: 6) {
                CycleTrack(
                    session: timer.session,
                    completedPomodoros: timer.completedPomodoros,
                    progress: progress
                )
                HStack {
                    Text("\(timer.completedPomodoros) of 4 done")
                    Spacer()
                    Text("Long break")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Button {
                    timer.startOrReset()
                } label: {
                    Label(timer.isRunning ? "Reset" : "Start", systemImage: timer.isRunning ? "arrow.counterclockwise" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .labelStyle(.titleAndIcon)
                .buttonStyle(.borderedProminent)
                .tint(timer.session.color)
                .keyboardShortcut(.defaultAction)

                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                .buttonStyle(.bordered)
                .help("Configure session lengths")

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "power")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("q")
                .help("Quit Tomatea")
            }
            .labelStyle(.iconOnly)
            .controlSize(.large)
        }
    }

    private var settingsView: some View {
        VStack(spacing: 10) {
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

                Button("Restore defaults") {
                    timer.updateDurations(.standard)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Restore default session lengths")
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

            HStack {
                Text("Start / reset shortcut")
                Spacer()
                ShortcutRecorder(shortcut: $shortcutSettings.shortcut)
            }
            .help("Starts the timer from anywhere, or resets it while running")

            if timer.isRunning {
                Text("Changes apply to the next session.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
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
}
