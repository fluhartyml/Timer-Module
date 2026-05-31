//
//  AlarmKitManager.swift
//  Timer Module
//
//  v0.2 — thin wrapper around AlarmKit's AlarmManager singleton.
//  Centralizes authorization + schedule + cancel for countdown timers.
//  Action dispatch (audioFile / webhook / shortcut) wires in at v0.8.
//
//  AlarmKit is iOS 26+ / macOS 26+. The whole file is guarded with
//  canImport because the macOS slice may not include AlarmKit on
//  every SDK; on platforms without it we provide a no-op fallback
//  so callers don't need their own #if guards.
//

import Foundation
#if canImport(AlarmKit)
import AlarmKit
#endif

@MainActor
final class AlarmKitManager {

    static let shared = AlarmKitManager()

    private init() {}

    // MARK: Authorization

    /// Request user permission to schedule alarms. Idempotent.
    /// Triggers the system permission sheet on first call.
    @discardableResult
    func requestAuthorization() async -> Bool {
        #if canImport(AlarmKit)
        do {
            let state = try await AlarmManager.shared.requestAuthorization()
            return state == .authorized
        } catch {
            return false
        }
        #else
        return false
        #endif
    }

    /// Current authorization state, no prompt.
    var isAuthorized: Bool {
        #if canImport(AlarmKit)
        return AlarmManager.shared.authorizationState == .authorized
        #else
        return false
        #endif
    }

    // MARK: Scheduling

    /// Schedule a countdown timer for the given duration, with the given title.
    /// Returns the AlarmKit alarm ID — caller persists this so cancel(...) can
    /// remove the alarm if the user pauses / stops / resets the timer.
    /// `timerID` round-trips back through metadata when the alarm fires so we
    /// can match it to the originating TimerData.
    func scheduleTimer(
        duration: TimeInterval,
        title: String,
        timerID: String
    ) async throws -> UUID {
        let id = UUID()
        #if canImport(AlarmKit)
        let metadata = TimerModuleAlarmMetadata(timerID: timerID)
        let attributes = AlarmAttributes(
            presentation: AlarmPresentation(title: title),
            metadata: metadata
        )
        let config = AlarmManager.AlarmConfiguration.timer(
            duration: duration,
            attributes: attributes
        )
        try await AlarmManager.shared.schedule(id: id, configuration: config)
        #endif
        return id
    }

    /// Cancel a previously-scheduled alarm by its AlarmKit ID.
    /// Safe to call on a no-longer-existing alarm.
    func cancelTimer(id: UUID) async {
        #if canImport(AlarmKit)
        try? await AlarmManager.shared.cancel(id: id)
        #endif
    }
}

#if canImport(AlarmKit)
/// Metadata round-tripped through AlarmKit so the alarm-fired handler can
/// resolve the originating TimerData.
struct TimerModuleAlarmMetadata: AlarmMetadata {
    let timerID: String
}
#endif
