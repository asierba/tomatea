import AppKit
import TomateaCore
import SwiftUI

struct PomodoroView: View {
    @ObservedObject var timer: PomodoroTimer
    @ObservedObject var shortcutSettings: GlobalShortcutSettings
    @ObservedObject var focusMode: FocusModeController
    @StateObject private var launchAtLogin = LaunchAtLogin()
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
                .buttonStyle(InkButtonStyle())
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

                Spacer()

                Button("Restore defaults") {
                    timer.updateDurations(.standard)
                }
                .help("Restore default session lengths")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            SettingsCard {
                durationRow(.focus, systemImage: "target", keyPath: \.focusMinutes, range: 1...120)
                durationRow(.shortBreak, systemImage: "cup.and.saucer.fill", keyPath: \.shortBreakMinutes, range: 1...60)
                durationRow(.longBreak, systemImage: "moon.fill", keyPath: \.longBreakMinutes, range: 1...60)
            }

            SettingsCard {
                SettingsRow(title: "Stop after break", systemImage: "pause.fill", tint: .gray) {
                    settingsSwitch($timer.stopAfterBreak)
                }
                .help("When off, the next focus session starts automatically after a break")

                SettingsRow(title: "Turn on Focus while focusing", systemImage: "bell.slash.fill", tint: .purple) {
                    settingsSwitch(Binding(
                        get: { focusMode.isEnabled },
                        set: { focusMode.setEnabled($0) }
                    ))
                }
                .help("Runs the \"\(FocusModeController.onShortcut)\" and \"\(FocusModeController.offShortcut)\" shortcuts, which you create in the Shortcuts app")

                if !focusMode.missingShortcuts.isEmpty {
                    missingShortcutsHint
                        .padding(6)
                } else if let error = focusMode.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(6)
                }
            }

            SettingsCard {
                SettingsRow(title: "Start / reset shortcut", systemImage: "keyboard", tint: .gray) {
                    ShortcutRecorder(shortcut: $shortcutSettings.shortcut)
                }
                .help("Starts the timer from anywhere, or resets it while running")

                SettingsRow(title: "Open at login", systemImage: "power", tint: .gray) {
                    settingsSwitch(Binding(
                        get: { launchAtLogin.isEnabled },
                        set: { launchAtLogin.setEnabled($0) }
                    ))
                }
                .help("Starts Tomatea automatically when you log in")

                if let error = launchAtLogin.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(6)
                }
            }

            if timer.isRunning {
                Text("Changes apply to the next session.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            launchAtLogin.refresh()
            focusMode.refresh()
        }
    }

    private var missingShortcutsHint: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(
                "Missing in Shortcuts: \(focusMode.missingShortcuts.map { "\"\($0)\"" }.joined(separator: ", "))",
                systemImage: "exclamationmark.triangle.fill"
            )
            .font(.footnote)
            .foregroundStyle(.orange)
            .fixedSize(horizontal: false, vertical: true)

            Button("Open Shortcuts") {
                NSWorkspace.shared.open(URL(string: "shortcuts://")!)
            }
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func durationRow(
        _ session: PomodoroSession,
        systemImage: String,
        keyPath: WritableKeyPath<PomodoroDurations, Int>,
        range: ClosedRange<Int>
    ) -> some View {
        let value = durationBinding(keyPath)
        return SettingsRow(title: session.title, systemImage: systemImage, tint: session.color) {
            HStack(spacing: 4) {
                TextField(session.title, value: clamped(value, to: range), format: .number)
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .frame(width: 44)
                Text("min")
                    .foregroundStyle(.secondary)
                Stepper(session.title, value: value, in: range)
                    .labelsHidden()
            }
        }
    }

    private func settingsSwitch(_ isOn: Binding<Bool>) -> some View {
        Toggle("", isOn: isOn)
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.mini)
            .tint(PomodoroSession.focus.color)
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
