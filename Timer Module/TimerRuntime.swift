//
//  TimerRuntime.swift
//  Timer Module
//
//  v0.3 — device-local runtime state for the active preset.
//  Holds which preset is currently the "front" timer on THIS device,
//  the running clock, AlarmKit cancel handle, and the status word.
//  Not SwiftData. Not synced via CloudKit. Each device owns its own
//  TimerRuntime instance (per Q6 / sync architecture: preset library
//  syncs, runtime state stays per-device).
//
//  Chain advance + AlarmKit scheduling wire in at v0.7 / v0.8.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class TimerRuntime {

    static let shared = TimerRuntime()

    /// On-screen status word. RUN / READY / HALT / COMPLETE per the BASIC
    /// heritage status vocabulary locked in Q12 / Q22 design decisions.
    enum Status: String {
        case ready
        case run
        case halt
        case complete
    }

    // MARK: State

    /// UUID of the preset currently shown as the active card on this device.
    /// nil = empty state (no active preset).
    var activePresetId: UUID?

    /// Date the currently-running countdown was started (or last resumed
    /// after a pause). nil while paused / ready / complete.
    var runningSince: Date?

    /// Seconds already accumulated from prior run segments (before the
    /// current runningSince started). Combined with the current segment
    /// for the on-screen display.
    var accumulatedSeconds: Int = 0

    /// AlarmKit cancel handle for the scheduled alarm tied to the current
    /// run. nil while ready / paused / complete. Used by stop / reset /
    /// pause to cancel the scheduled alarm.
    var alarmKitID: UUID?

    /// Current display status — drives the on-screen status word and the
    /// available transport buttons (play / pause / stop / next / prev).
    var status: Status = .ready

    // MARK: Computed

    /// Total elapsed time for the on-screen display. Combines
    /// accumulatedSeconds (from prior segments) with the live elapsed
    /// from runningSince (if currently running). Drives the 1 Hz UI tick.
    var displayedElapsedSeconds: Int {
        guard let runningSince else { return accumulatedSeconds }
        return accumulatedSeconds + Int(Date().timeIntervalSince(runningSince))
    }

    // MARK: Lifecycle helpers (stubs — full wiring at v0.4 / v0.7)

    /// Clear all runtime state. Returns to READY on no preset.
    func clear() {
        activePresetId = nil
        runningSince = nil
        accumulatedSeconds = 0
        alarmKitID = nil
        status = .ready
    }

    private init() {}
}
