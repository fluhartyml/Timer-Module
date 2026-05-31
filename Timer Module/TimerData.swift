//
//  TimerData.swift
//  Timer Module
//
//  Created by Michael Fluharty on 5/30/26.
//

import Foundation
import SwiftData

@Model
final class TimerData {

    // MARK: Identity
    var id: UUID = UUID()

    // MARK: User content
    var notation: String = ""
    var note: String = ""

    // MARK: Mode + duration
    var modeRaw: String = TimerMode.countDown.rawValue
    var durationSeconds: Int = 0

    // MARK: Chain / dating (mutually exclusive — UI enforces)
    var sequenceNumber: Int? = nil
    var targetDate: Date? = nil

    // MARK: Persistence behavior (per-preset; default true = chain waits for ack)
    var isPersistent: Bool = true

    // MARK: Action (one of four — alarmKitDefault / audioFile / webhook / shortcut)
    var actionKindRaw: String = TimerActionKind.alarmKitDefault.rawValue
    var audioFileURL: URL? = nil
    var shortcutName: String? = nil
    var webhookURL: URL? = nil
    var webhookMethod: String? = nil
    var webhookBody: String? = nil

    // MARK: Sort
    var displayOrder: Int? = nil

    // MARK: Metadata
    var createdDate: Date = Date()
    var updatedDate: Date = Date()

    init(
        notation: String = "",
        note: String = "",
        mode: TimerMode = .countDown,
        durationSeconds: Int = 0
    ) {
        self.id = UUID()
        self.notation = notation
        self.note = note
        self.modeRaw = mode.rawValue
        self.durationSeconds = durationSeconds
        self.createdDate = Date()
        self.updatedDate = Date()
    }

    // MARK: Enum accessors (raw String storage for SwiftData + CloudKit)
    var mode: TimerMode {
        get { TimerMode(rawValue: modeRaw) ?? .countDown }
        set { modeRaw = newValue.rawValue }
    }

    var actionKind: TimerActionKind {
        get { TimerActionKind(rawValue: actionKindRaw) ?? .alarmKitDefault }
        set { actionKindRaw = newValue.rawValue }
    }
}

enum TimerMode: String, Codable, CaseIterable {
    case countUp
    case countDown
}

enum TimerActionKind: String, Codable, CaseIterable {
    case alarmKitDefault
    case audioFile
    case webhook
    case shortcut
}
