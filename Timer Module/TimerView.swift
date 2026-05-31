//
//  TimerView.swift
//  Timer Module
//
//  v0.4 — the single front-and-center timer card.
//  Shows notation, mode, duration (picker when ready / numerals when
//  running), status word, inline note, and the media-transport
//  button row (play / pause / stop / next / previous).
//
//  Wires button taps to TimerRuntime state transitions. Does NOT yet
//  schedule AlarmKit alarms (v0.8) or advance through chains (v0.7).
//  That logic lands in the next milestones; this view is the shell
//  the runtime drives.
//

import SwiftUI

struct TimerView: View {

    /// The preset this card is showing. nil = empty state (no active preset).
    let preset: TimerData?

    @Environment(TimerRuntime.self) private var runtime

    /// Drives the 1 Hz on-screen countdown tick while running.
    /// Independent of AlarmKit (which drives the actual system alert).
    private let displayTick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        if let preset {
            cardBody(for: preset)
        } else {
            emptyState
        }
    }

    // MARK: Empty state (no active preset)

    private var emptyState: some View {
        ContentUnavailableView(
            "No active timer",
            systemImage: "timer",
            description: Text("Add a preset or load samples to begin.")
        )
    }

    // MARK: Active card

    @ViewBuilder
    private func cardBody(for preset: TimerData) -> some View {
        VStack(spacing: 16) {
            // Notation (read-only here; edit via EditorSheet at v0.6)
            Text(preset.notation.isEmpty ? "Untitled timer" : preset.notation)
                .font(.title2.weight(.semibold))
                .lineLimit(2)

            // Mode badge
            modeRow(for: preset)

            // Big numerals / picker depending on status
            numeralsArea(for: preset)

            // Status word — RUN / READY / HALT / COMPLETE
            statusWord

            // Inline note (visible while timer ticks per Q19 design intent)
            if !preset.note.isEmpty {
                Text(preset.note)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }

            // Media-transport button row (PLAY / PAUSE / STOP / NEXT / PREVIOUS)
            transportRow(for: preset)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(focusRing)
    }

    private func modeRow(for preset: TimerData) -> some View {
        HStack(spacing: 8) {
            Image(systemName: preset.mode == .countDown ? "arrow.down.circle" : "arrow.up.circle")
            Text(preset.mode == .countDown ? "Countdown" : "Count up")
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func numeralsArea(for preset: TimerData) -> some View {
        switch runtime.status {
        case .ready, .complete:
            // Static display of the configured duration
            Text(formatted(seconds: preset.durationSeconds))
                .font(.system(size: 56, weight: .medium, design: .monospaced))
                .onReceive(displayTick) { _ in /* idle */ }
        case .run, .halt:
            // Live countdown — uses displayedElapsedSeconds for count-up,
            // or remaining = duration - elapsed for countdown
            Text(formatted(seconds: remainingOrElapsed(for: preset)))
                .font(.system(size: 56, weight: .medium, design: .monospaced))
                .foregroundStyle(runtime.status == .run ? .green : .orange)
                .onReceive(displayTick) { _ in /* triggers SwiftUI re-eval */ }
        }
    }

    private var statusWord: some View {
        Text(runtime.status.rawValue.uppercased())
            .font(.subheadline.weight(.bold))
            .foregroundStyle(statusColor)
            .tracking(2)
    }

    private var statusColor: Color {
        switch runtime.status {
        case .ready:    return .secondary
        case .run:      return .green
        case .halt:     return .orange
        case .complete: return .blue
        }
    }

    @ViewBuilder
    private func transportRow(for preset: TimerData) -> some View {
        HStack(spacing: 20) {
            switch runtime.status {
            case .ready, .complete:
                transportButton("Play", systemImage: "play.fill") { startTimer(for: preset) }
            case .run:
                transportButton("Previous", systemImage: "backward.fill", disabled: !canGoPrev(for: preset)) { stepPrev() }
                transportButton("Pause", systemImage: "pause.fill") { pauseTimer() }
                transportButton("Stop", systemImage: "stop.fill") { stopTimer() }
                transportButton("Next", systemImage: "forward.fill", disabled: !canGoNext(for: preset)) { stepNext() }
            case .halt:
                transportButton("Play", systemImage: "play.fill") { resumeTimer(for: preset) }
                transportButton("Stop", systemImage: "stop.fill") { stopTimer() }
            }
        }
    }

    private func transportButton(_ label: String, systemImage: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.bordered)
        .disabled(disabled)
        .accessibilityLabel(label)
    }

    private var focusRing: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(runtime.status == .run ? Color.green : Color.clear, lineWidth: 2)
    }

    // MARK: Runtime transitions (stubs — AlarmKit wiring lands at v0.8)

    private func startTimer(for preset: TimerData) {
        runtime.activePresetId = preset.id
        runtime.runningSince = Date()
        runtime.accumulatedSeconds = 0
        runtime.status = .run
    }

    private func resumeTimer(for preset: TimerData) {
        runtime.runningSince = Date()
        runtime.status = .run
    }

    private func pauseTimer() {
        if let started = runtime.runningSince {
            runtime.accumulatedSeconds += Int(Date().timeIntervalSince(started))
        }
        runtime.runningSince = nil
        runtime.status = .halt
    }

    private func stopTimer() {
        runtime.clear()
    }

    // Chain stepping — real implementation arrives at v0.7
    private func canGoNext(for preset: TimerData) -> Bool { preset.sequenceNumber != nil }
    private func canGoPrev(for preset: TimerData) -> Bool { (preset.sequenceNumber ?? 0) > 1 }
    private func stepNext() { /* v0.7 */ }
    private func stepPrev() { /* v0.7 */ }

    // MARK: Formatting

    private func remainingOrElapsed(for preset: TimerData) -> Int {
        let elapsed = runtime.displayedElapsedSeconds
        switch preset.mode {
        case .countDown: return max(preset.durationSeconds - elapsed, 0)
        case .countUp:   return elapsed
        }
    }

    private func formatted(seconds: Int) -> String {
        let s = max(seconds, 0)
        let days = s / 86_400
        let hours = (s % 86_400) / 3600
        let minutes = (s % 3600) / 60
        let secs = s % 60
        if days > 0 {
            return String(format: "%dd %02d:%02d:%02d", days, hours, minutes, secs)
        }
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }
}

#Preview {
    TimerView(
        preset: TimerData(
            notation: "Work Session",
            note: "focused work, no interruptions",
            mode: .countDown,
            durationSeconds: 4 * 3600
        )
    )
    .environment(TimerRuntime.shared)
    .padding()
}
