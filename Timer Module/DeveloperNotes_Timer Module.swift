//
//  DeveloperNotes_Timer Module.swift
//  Timer Module
//
//  Created by Michael Fluharty on 5/30/26.
//

// MARK: - Timer Module — Developer Notes
// Version: 0.0 (pre-MVP — Xcode scaffold created 2026-05-30)
// Developer: Michael Lee Fluharty
// License: GPL v3 ("share and share alike with attribution required")
// Created: 2026-05-30
// Repo: github.com/fluhartyml/Timer Module (public)
// Bundle ID: com.nightgard.Timer-Module
// Platforms: iPhone, iPad, Mac (primary) + visionOS (bonus,
//   untested — left in from Xcode universal-template default;
//   ships if it works, no sleep lost if it doesn't)
// Deployment targets: iOS 26.4, macOS 26.4, visionOS 26.4
//
// ============================================================
// VISION — DO ONE THING WELL (Unix philosophy)
// ============================================================
//
// One thing: set a timer, hear it actually ring.
//
// The whole app is one screen with one front-and-center timer.
// Set a duration, tap Start, lock the device, walk away. When
// time's up, the device rings — really rings, via AlarmKit,
// not a silent notification that might-or-might-not buzz.
//
// Growth is additive on a perfected core. Every feature must
// pass the question "does this make the one thing better, or
// is this scope creep?"
//
// ============================================================
// DIFFERENTIATOR vs APPLE CLOCK
// ============================================================
//
// Apple's Clock app ships free on every iOS device. iOS 17+
// added named multi-timers, which closes the historical gap
// around labeling. Timer Module has to clear that bar.
//
// THE differentiator (Michael's call, 2026-05-30): Apple Clock
// is for AD-HOC timers — set one, fire it, forget it. Timer
// Module is for the TIMERS YOU KEEP — saved presets where
// each one carries a NOTE about what the alarm is FOR.
//
// "save the alarm and note what the alarm is for" — Michael.
//
// In Clock you set "15 min" and forget what 15 was for. In
// Timer Module you save a preset called "Break session" with
// a note "step away from the screen, walk around" — the note
// is the preset's purpose, not optional metadata.
//
// Capabilities Timer Module has that Apple Clock doesn't:
//   - Curated, named preset library (Clock has "Recents")
//   - Per-preset instructions/notes carrying purpose / context
//   - CloudKit sync of the preset library across devices
//   - User-assigned sequence chaining (auto-advance to the
//     next preset on complete)
//   - On-complete action firing (Shortcut or webhook), which
//     unlocks HomeKit, HA, Music, Calendar, IFTTT, etc.
//   - Widget-as-launcher (tap widget to start that preset)
//
// Anywhere there's tension between "ad-hoc convenience"
// (Clock's strength) and "preset-as-first-class-object"
// (this app's strength), go with the preset model. The
// preset library IS the product.
//
// ============================================================
// IN SCOPE — WHAT TIMER MODULE IS
// ============================================================
//
//   • Single front-and-center timer surface — one card, one
//     active preset, all visible
//   • Count up AND countdown modes
//   • Duration input — composite days/hours/minutes/seconds
//     picker. Unbounded range (1 second minimum). Seconds
//     available but not required; user can leave them at 0
//     for casual whole-minute or quarter-hour presets, or
//     fill them in for cooking, microwave, sports timing.
//   • Media-transport control set: PLAY / PAUSE / STOP /
//     NEXT / PREVIOUS. Tracks = presets in the chain;
//     transport buttons act on the chain like a media player
//     acts on a playlist. PAUSE keeps the chain alive; STOP
//     aborts the chain; NEXT/PREVIOUS skip forward/back to
//     neighboring presets. Standalone presets hide NEXT/PREV
//     since there's no chain to navigate. Resolved Q5
//     (2026-05-30).
//   • 18pt monospaced numerals as the visual anchor
//   • Status vocabulary on screen: RUN / READY / HALT / COMPLETE
//     (BASIC heritage: "locked, loaded, and READY")
//   • Per-timer instructions — multi-line text box on every
//     preset for what the alarm is for and any instructions
//     to follow during the run.
//     Michael 2026-05-30: "each timer should have a text box
//     where the user can define the instructions or commenting
//     notes for each timer"
//     Design implication: the note must be VISIBLE on the card
//     body during the run (not just hidden behind a sheet) so
//     instructions can be followed while the timer ticks. The
//     edit sheet is for editing; the card view shows the text
//     inline.
//   • Preset library — multiple saved named/noted timers;
//     exactly one active at a time
//   • Sequence chaining — each preset has a user-assigned
//     sequenceNumber; on complete the system auto-advances to
//     the next-higher sequence and starts it.
//     Michael 2026-05-30: "each timer should be able to be
//     assigned a sequence number by the user"
//     Example chain: Work=1, Break=2, Stretch=3.
//   • Real system-level alarm via AlarmKit (iOS 26+) — the
//     device actually rings, locked or not, app foreground or
//     not. This is the do-one-thing-well differentiator vs
//     silent-notification timer apps.
//   • On-complete action (per preset, unified Q22 model).
//     Every preset configures exactly ONE of:
//       1. AlarmKit default — system alarm sound rings, no
//          custom audio or external action
//       2. Audio file — user-imported audio plays at
//          completion (replaces system sound). Source via
//          Files picker or Apple Music / personal library
//       3. Webhook — HTTP request fires at completion
//       4. Shortcut — named Apple Shortcut runs at completion
//     This unified per-preset action is the seam that unlocks
//     HomeKit / HA / Music / Calendar / IFTTT / custom-server
//     integration without Timer Module knowing about any of
//     those — a Shortcut or webhook receiver does the work.
//     Replaces the earlier "app-level sound + per-preset
//     webhook/shortcut" split (Q6 + Q8 superseded).
//   • SwiftData persistence — preset library survives close
//   • CloudKit private DB sync — preset library only (not
//     running state)
//   • Universal app — iPhone, iPad, Mac (primary, tested);
//     visionOS included as bonus-territory (left in from
//     Xcode template, not actively tested)
//
//   Widget Extension (separate target, "Timer Module Widget"):
//     • Home Screen widget — current/active timer countdown,
//       configurable via App Intent (which preset to show)
//     • Lock Screen widget
//     • Live Activity — Lock Screen banner + Dynamic Island
//       (compact + expanded + minimal regions)
//     • Control Center widget (iOS 18+) — Start/Stop toggle
//       for a chosen preset via StartTimerIntent
//     • App Intents — Siri / Shortcuts / Spotlight surface
//
// ============================================================
// ARCHITECTURE
// ============================================================
//
// STORAGE — Split between synced and device-local.
//
//   Michael's call 2026-05-30: "i di want a universal synch
//   across devices, not so much the status of the timer
//   countdown but the actual timers and names"
//
//   Sync scope:
//
//     SYNCED via CloudKit (the preset library — every device
//     sees the same named, noted timers):
//       • TimerData.id, notation, note, mode, durationSeconds,
//         sequenceNumber, actionKind, shortcutName, webhookURL,
//         webhookMethod, webhookBody, webhookHeaders,
//         createdDate, updatedDate, displayOrder
//
//     NOT SYNCED (per-device runtime state — each device owns
//     its own running timer independently):
//       • Which preset is the front/active one on this device
//       • runningSince (Date the current run started)
//       • accumulatedSeconds (time-on-clock for this run)
//       • alarmKitID (handle for cancelling the local alarm)
//       • Current status (READY / RUN / HALT / COMPLETE)
//
//   Why this split: starting "Work session" on the Mac at 9am
//   shouldn't make the iPhone simultaneously ring at 1pm. Each
//   device runs its own instance. But all devices share the
//   curated library of named, noted presets.
//
//   Implementation:
//     SwiftData ModelContainer (CloudKit-backed, private DB)
//       Schema: [TimerData] — the preset definitions only.
//
//     Runtime state: @Observable singleton (TimerRuntime) held
//       in app environment. Not persisted to SwiftData. If
//       cross-launch recovery is needed (e.g. app crashed
//       mid-run), AlarmKit is the source of truth for "what
//       was scheduled" — query AlarmManager on launch and
//       reconcile. UserDefaults can optionally hold the
//       activePresetId so the front preset survives a relaunch.
//
//   iCloud container: iCloud.com.nightgard.timer-module
//     (PENDING — provisioned via Xcode Signing & Capabilities
//      once added to ModelConfiguration. Currently the
//      entitlements file lists CloudKit but no container ID.
//      Do not hand-edit the entitlements; use the Xcode UI.)
//
// ALARM PATH — AlarmKit, unconditional.
//   Deployment target is 26.4 across all Apple platforms here,
//   so AlarmKit is always available. No #if canImport(AlarmKit)
//   or #available(iOS 26.0, ...) guards needed.
//
//   AlarmKitManager singleton (@MainActor) wraps:
//     - requestAuthorization() async throws
//     - scheduleTimer(title:duration:timerID:) async → UUID
//     - cancelTimer(id:)
//
//   TimerRuntime.alarmKitID holds the returned UUID so Stop /
//   Reset can cancel a scheduled alarm cleanly. complete()
//   does not need to cancel — by definition the alarm has
//   already fired.
//
//   First Start press → trigger authorization sheet. If denied,
//   surface a one-line inline banner ("AlarmKit access needed
//   for real alarms"). Don't pester.
//
//   AlarmKit on Mac — verify availability at first Mac build.
//   If absent on the macOS slice, fall back to
//   UNUserNotificationCenter behind a single #if canImport
//   guard. This is the one place the guard re-earns its keep.
//
// UI TICK — Two separate concerns, intentionally:
//   - SwiftUI Timer.publish(every: 1).autoconnect() drives the
//     on-screen countdown numerals (cosmetic / glanceable).
//   - AlarmKit drives the actual system-level alert that fires
//     when locked / backgrounded / app-killed (functional).
//   These are independent. The UI tick lying is fine; the
//   AlarmKit fire is the source of truth for "the alarm went
//   off."
//
// ACTION FIRING — on-complete shortcut or webhook execution.
//   Each TimerData carries optional action config:
//     - actionKind: enum { none, shortcut, webhook }
//     - shortcutName: String?         (Apple Shortcuts name)
//     - webhookURL: URL?              (the endpoint)
//     - webhookMethod: String?        (GET/POST/PUT/DELETE)
//     - webhookBody: String?          (JSON or form-encoded)
//     - webhookHeaders: [String:String]? (auth, content-type)
//
//   Action TIMING — open question, see OPEN below. Default
//   plan: fire when AlarmKit alarm rings (system level,
//   regardless of foreground state).
//
//   SHORTCUT INVOCATION — use the Shortcuts app's published
//   Run Shortcut App Intent (preferred — runs in-place,
//   non-blocking) rather than the shortcuts:// URL scheme.
//
//   WEBHOOK INVOCATION — URLSession.shared.dataTask(with:
//   URLRequest). Set method, headers, body from the config.
//   Background execution: AlarmKit's alarm-fired handler has
//   limited background time — request a beginBackgroundTask
//   to extend if the webhook is slow.
//
//   AUTH for webhooks — out of scope for v1 beyond setting
//   custom headers (which covers most simple cases like a
//   bearer token in Authorization header). No OAuth flow.
//
// WIDGET EXTENSION — separate target, three widget kinds:
//   - Home Screen widget (WidgetKit + AppIntentTimelineProvider)
//   - Live Activity (ActivityKit, Lock Screen + Dynamic Island)
//   - Control Center widget (ControlWidget, iOS 18+)
//   All three registered in Timer_Module_WidgetBundle.swift.
//
//   App ↔ Widget data sharing: needs an App Group entitlement
//   (PENDING — add via Xcode Signing & Capabilities) so the
//   main app can write the currently-active preset snapshot
//   and the widget can read it. Suggested App Group ID:
//   group.com.nightgard.timer-module.
//
//   Live Activity vs AlarmKit's built-in: AlarmKit on iOS 26
//   ships a system-owned countdown Live Activity automatically
//   when scheduleTimer(...) is called. The custom Live Activity
//   in this app is for richer Dynamic Island content (running
//   preset name, accumulated/remaining numerals, custom colors)
//   and exists alongside AlarmKit's system one. Do not try to
//   replace AlarmKit's; supplement it.
//
// ============================================================
// DATA MODEL
// ============================================================
//
// TimerData (@Model, SwiftData, CloudKit-synced)
//   id: UUID
//   notation: String                  — preset name (short)
//   note: String                      — instructions / purpose
//                                       (multi-line, shown
//                                       inline on card body)
//   mode: enum {countUp, countDown}
//   durationSeconds: Int              — total duration in
//                                       seconds (supports
//                                       second-precision up
//                                       to arbitrary length)
//   sequenceNumber: Int?              — chain position; nil =
//                                       standalone
//   isPersistent: Bool                — true = timer holds
//                                       focus until user
//                                       acknowledges the
//                                       alarm, then releases
//                                       to next preset.
//                                       false = chain
//                                       advances immediately
//                                       on complete.
//                                       Default: true.
//   actionKind: enum {alarmKitDefault, audioFile, webhook,
//                     shortcut} — unified Q22 model. Every
//                     preset is exactly one of these. Default
//                     for a new preset = alarmKitDefault.
//   audioFileURL: URL?                — bookmark to user-
//                                       imported audio file
//                                       (Files-picker or
//                                       MusicKit reference);
//                                       only used when
//                                       actionKind = audioFile
//   shortcutName: String?             — only used when
//                                       actionKind = shortcut
//   webhookURL: URL?                  — only used when
//                                       actionKind = webhook
//   webhookMethod: String?
//   webhookBody: String?
//   webhookHeaders: [String:String]?
//   displayOrder: Int?                — user sort within list
//   targetDate: Date?                 — optional user-declared
//                                       date. nil = preset is
//                                       eligible for the chain.
//                                       Non-nil = one-off,
//                                       mutually exclusive
//                                       with sequenceNumber
//                                       (UI enforces). No auto-
//                                       fire — metadata only.
//                                       Synced via CloudKit.
//                                       Resolved Q24.
//   createdDate: Date
//   updatedDate: Date
//
// TimerRuntime (@Observable singleton, device-local, NOT
// SwiftData)
//   activePresetId: UUID?
//   runningSince: Date?
//   accumulatedSeconds: Int
//   alarmKitID: UUID?
//   status: enum {ready, run, halt, complete}
//
// ============================================================
// ROADMAP — WHAT TIMER MODULE WILL DO
// ============================================================
//
// Living document. Items below are organized by capability
// area, not by ship order. Each item is tagged with provenance:
//   [DECLARED]  — Michael's explicit decision (chat or action)
//   [INFERRED]  — Claude's read from context, pending confirm
//   [OPEN]      — placeholder for Michael to fill in
//
// --- CORE TIMER ---
//   [DECLARED] Single front-and-center timer surface
//   [DECLARED] Count up AND countdown modes
//   [DECLARED] Trigger-at duration input + ±1 fine-tuning
//   [DECLARED] Start / Stop / Reset / Complete actions
//   [DECLARED] 18pt monospaced numerals
//   [DECLARED] Status vocabulary: RUN / READY / HALT / COMPLETE
//   [OPEN]     Interval/split timers, auto-restart, trigger-
//              on-shake, custom duration units (hours,
//              seconds), other behaviors TBD
//
// --- ALARM / RINGING ---
//   [DECLARED] Real system-level alarm via AlarmKit (iOS 26+)
//   [SUPERSEDED] App-level alarm sound idea (Q6) folded into
//              the unified per-preset action picker (Q22).
//              Sound choice is now part of the action field,
//              not a separate app setting.
//   [INFERRED] AlarmKit's built-in Live Activity used as the
//              primary "alarm fired" surface
//   [DECLARED] No bundled ringtone bank (licensing). Default
//              sound = AlarmKit's system default; all custom
//              sounds come from user-imported content.
//              Resolved Q17.
//   [DECLARED] User audio import via Files picker AND Apple
//              Music / personal library (MusicKit). Voice
//              Memos NOT supported in v1. Resolved Q16.
//   [OPEN]     AlarmKit + custom sound — verify whether
//              AlarmKit lets us pass a custom sound or
//              whether the custom audio has to play via a
//              separate AVAudioSession when the alarm rings.
//   [DECLARED] No app-side escalating volume, custom haptics,
//              or vibration-only mode. Users wanting those
//              configure a Shortcut or webhook receiver to
//              do it. Resolved by Q22.
//
// --- PRESETS (THE differentiator) ---
//   [DECLARED] Saved named alarm + a note describing what the
//              alarm is FOR. The note isn't optional context;
//              the note carries the preset's purpose.
//              Canonical examples (use in README, screenshots,
//              App Store description, sample data):
//                • Work session         — 4h, "heads-down block"
//                • Break session        — 15 min, "step away"
//                • Stretch at your desk — 5 min, "shoulders /
//                                          neck / wrists"
//   [DECLARED] Multiple saved presets, exactly one active at a
//              time
//   [INFERRED] Switch active preset via list (sidebar on iPad/
//              Mac, sheet on iPhone)
//   [DECLARED] Duration range is unbounded (1 second minimum,
//              no upper cap — supports anything from 90s
//              exercise intervals to multi-day rituals).
//              Resolved Q1 (2026-05-30).
//   [DECLARED] No categories / tags / color-coding /
//              favorites. Chain ordering + standalone bucket
//              are the only organization. Resolved Q21.
//   [DECLARED] First launch = empty library + add-your-first
//              empty state. Settings sheet has a "Load sample
//              presets" button. Each canonical sample has a
//              deterministic UUID; tapping the button adds
//              only missing samples (skip if already present)
//              so repeated taps don't duplicate. Resolved
//              Q10.
//
// --- CHAINING / SEQUENCING ---
//   [DECLARED] User-assigned sequenceNumber on each preset.
//              On complete, advance to the next-higher
//              sequenceNumber and auto-start.
//   [DECLARED] End-of-chain is natural — the chain ends when
//              the next numbered slot is empty (no explicit
//              config, no loop feature). Resolved Q2.
//   [DECLARED] No duplicate sequence numbers within a chain.
//              No gaps either — UI picker auto-suggests the
//              next-available contiguous number, and deletion
//              auto-compacts (N+1, N+2... shift down to fill).
//              Sequence numbers are always contiguous 1...N
//              by construction; runtime needs no gap-handling
//              logic. Resolved Q3 + Q14.
//   [DECLARED] Full media-transport control set: PLAY /
//              PAUSE / STOP / NEXT / PREVIOUS. PAUSE keeps
//              chain alive; STOP aborts; NEXT/PREVIOUS skip
//              forward/back. Tracks = presets in the chain.
//              Resolved Q5 (with Q5 follow-up).
//   [DECLARED] v1.0 ships single chain only — sequenceNumber
//              is one global pool across the whole library.
//              No chainID/chainName grouping. Resolved Q4.
//   [FUTURE]   Multi-chain expansion (post-v1.0). Vision:
//              7 chains (days of week), then 31 (days of
//              month), eventually 365 (days of year) — one
//              chain per calendar day. Schema migration adds
//              a chainID column when this ships.
//   [OPEN]     Presets outside any chain — sequenceNumber=nil
//              for standalone — confirm the UX (sorted at top,
//              bottom, separate section)?
//
// --- INTEGRATIONS (on-complete action) ---
//   [DECLARED] Run Apple Shortcut on timer complete
//              (named shortcut, invoked via App Intent path)
//   [DECLARED] Execute webhook on timer complete (HTTP
//              GET/POST/PUT/DELETE to user-supplied URL with
//              optional headers and body)
//              These two cover HomeKit/HA/Music/Calendar/IFTTT
//              indirectly — Timer Module doesn't integrate
//              with those directly, the Shortcut or webhook
//              receiver does.
//   [DECLARED] Action fires at the conclusion of the timer
//              (background fire, the moment AlarmKit's alarm
//              rings) — not gated on user acknowledgment.
//              Resolved Q7.
//   [DECLARED] Per-preset isPersistent: Bool toggle. True =
//              timer holds focus until user acknowledges the
//              alarm, then releases to next preset. False =
//              chain advances immediately on complete.
//              Default: true. Resolved Q9.
//   [DECLARED] Per-preset unified action picker (Q22, this
//              supersedes Q8's webhook-OR-shortcut radio):
//              exactly one of {alarmKitDefault, audioFile,
//              webhook, shortcut} per preset.
//   [OPEN]     Webhook auth beyond custom headers (OAuth flow,
//              cert pinning, etc) — likely out of scope.
//
// --- SURFACES (beyond the main app screen) ---
//   [DECLARED] Home Screen widget — Widget target added
//              2026-05-30 with stock template
//   [DECLARED] Lock Screen widget — same target
//   [DECLARED] Live Activity (Lock Screen banner + Dynamic
//              Island compact/expanded/minimal) — same target
//   [DECLARED] Control Center widget (iOS 18+) with
//              StartTimerIntent toggle — same target
//   [DECLARED] App Intents — Siri / Shortcuts / Spotlight
//              configurability via ConfigurationAppIntent
//   [DECLARED] No watchOS — Michael is no longer a watchOS
//              proponent. SUPPORTED_PLATFORMS stays at
//              iPhone/iPad/Mac/visionOS. Resolved Q11.
//   [DECLARED] No special visionOS-tailored work. Ships with
//              whatever the universal-template auto-layout
//              provides. Bonus if it works there, not
//              actively tested. Resolved Q23.
//
// --- PERSISTENCE & SYNC ---
//   [DECLARED] SwiftData storage for preset library
//   [DECLARED] CloudKit private DB sync of the PRESET LIBRARY
//              across user's devices — iCloud container PENDING
//              provisioning via Xcode UI
//   [DECLARED] Runtime state STAYS PER-DEVICE — explicitly NOT
//              synced
//   [DECLARED] App Group entitlement for app↔widget data
//              (PENDING provisioning; suggested ID
//              group.com.nightgard.timer-module)
//
// --- PLATFORMS ---
//   [DECLARED] iPhone (iOS 26.4)
//   [DECLARED] iPad (iOS 26.4)
//   [DECLARED] Mac (macOS 26.4, native — not Catalyst)
//   [DECLARED] visionOS — bonus-territory. Left in from
//              Xcode universal template (SUPPORTED_PLATFORMS
//              includes xros/xrsimulator,
//              TARGETED_DEVICE_FAMILY="1,2,7"). Not actively
//              tested by Michael. Ships if it works there,
//              no fire-drill if it doesn't. Don't make
//              marketing claims about visionOS support.
//              Resolved Q23.
//   [DECLARED] No watchOS — confirmed not on the roadmap.
//              Resolved Q11.
//
// --- VISUAL IDENTITY ---
//   [INFERRED] RUN/READY/HALT/COMPLETE on-screen labels
//              (BASIC heritage; well-documented preference)
//   [DECLARED] System defaults throughout — system semantic
//              colors, system fonts, .thinMaterial card fill,
//              iOS-handled dark/light mode. No custom theme
//              system, no amber CRT mode, no customizable
//              chrome. Resolved Q12.
//
// --- HISTORY / STATS ---
//   [DECLARED] Console-style completion log. Local-only
//              (separate SwiftData container, no CloudKit),
//              resets on app delete+reinstall. Resolved Q19.
//   [OPEN]     Streak / daily / weekly stats (could be
//              derived from completion log; separate UI).
//   [OPEN]     Most-used presets (also derivable from log).
//
// --- SHARING / IMPORT-EXPORT ---
//   [DECLARED] No sharing surface in v1. No portable file
//              format, no AirDrop, no QR, no share-link.
//              Presets live in user's own library only;
//              CloudKit syncs to user's own devices only.
//              Resolved Q20.
//
// --- DISTRIBUTION ---
//   [DECLARED] Public GitHub repo, GPL v3
//   [DECLARED] Paid app, premium positioning, RECURRING
//              subscription (not one-time). Target price tier
//              $100.00 or more. Design must clear a premium-
//              app capability bar AND each release cycle must
//              add enough value to justify continued
//              subscription. Resolved Q13.
//   [OPEN]     TestFlight beta — Michael has no firsthand
//              TestFlight experience yet
//
// ============================================================
// INTERVIEW — DESIGN DECISIONS Q&A LOG
// ============================================================
//
// Each open question is walked through as a back-and-forth.
// Questions are asked one at a time; answers update the
// ROADMAP / DATA MODEL / IN SCOPE sections above as decisions
// land. This section is the chronological reasoning record so
// future-reader can see WHY each call was made.
//
// --- Q1 (2026-05-30): Duration field precision and range ---
// Q: Whole minutes 1-240 (current plan) hits exactly the
//    ceiling at the "Work session" example. Future presets
//    might want sub-minute precision (90-second exercise
//    interval) or longer-than-4h durations (overnight,
//    deep-work blocks, slow-cooker). How fine-grained at the
//    bottom (seconds? minutes?), how long at the top (4h?
//    24h? unbounded?), one field or unit picker?
// A: Michael 2026-05-30 (first pass): "i would have to say a
//    duration range is infinite 24hrs 7 days a week"
//    Michael 2026-05-30 (richer pass): the user reasoned
//    through real cases — cake baking and microwave reheating
//    need second accuracy; an Olympic event timer needs
//    second accuracy (or finer). Conclusion: don't take
//    seconds away from the user. If they don't need that
//    precision they leave seconds at 0 and round to whatever
//    they want (quarter-hour increments was the example given).
//    DECISION:
//      • Duration range unbounded — 1 second minimum, no
//        practical upper limit
//      • Seconds precision available, not required
//      • Input is a composite (days/hours/minutes/seconds
//        fields or H:MM:SS picker with day overflow), not a
//        single-unit input
//      • TimerData.durationSeconds stored as Int seconds
//    Use cases that drove the call: cooking, microwave
//    reheating, sports event timing, plus the original
//    Work/Break/Stretch whole-minute presets.
//
// --- Q2 (2026-05-30): End-of-chain behavior ---
// Q: After the last preset in a sequence completes (e.g.
//    Work=1 → Break=2 → Stretch=3, then Stretch finishes),
//    what happens? Loop back to sequence 1 and start over?
//    Stop and let the user manually restart? User-configurable
//    per chain (some loop forever, others run once)?
// A: Michael 2026-05-30: end-of-chain is a NATURAL event,
//    no explicit configuration. The chain ends when the next
//    numbered slot is empty. So if the user set timers
//    numbered 1-5, the chain ends at 6 because no timer 6
//    exists. If only one timer is in the sequence, the chain
//    ends after that one. The user doesn't choose loop-or-
//    stop; the absence of a next number IS the stop.
//    DECISION:
//      • No loopOnComplete field on TimerData
//      • No chain-level configuration object
//      • Runtime: on complete, look for the next-higher
//        sequenceNumber present in the library; if found,
//        start it; if not, stop. Repeat.
//      • No "loop forever" feature by design. To repeat,
//        user manually restarts the first preset.
//      • Implication for gaps within (1, 3, 5 — skipping 2
//        and 4): Michael's answer addresses the after-last
//        case but not the gap-within case. Plain reading of
//        "look for next-higher" suggests gaps are skipped
//        (1 → 3 → 5 → end). Confirm if a gap should instead
//        end the chain.
//
// --- Q3 (2026-05-30): Sequence number ties ---
// Q: What if two presets both get sequence number 3? Say
//    you've got Work=1, Break=2, Stretch=3, and then create
//    a "Quick break" also numbered 3. When Break=2 finishes,
//    which sequence-3 timer runs next? Disallow ties at edit
//    time, allow ties and pick alphabetically, allow ties
//    and pick randomly, something else?
// A: Michael 2026-05-30: "i think if multiple sequences have
//    duplicate numbers an error should be called or the
//    sequence selector should take that number and not let
//    you use it for another timer in that sequence"
//    DECISION:
//      • No duplicate sequence numbers within a chain
//      • Preferred UX: the picker prevents picking an
//        already-used number (greyed out / hidden from list)
//      • Fallback UX: free-text input with validation that
//        rejects duplicates on save
//      • Note: Michael's phrasing "multiple sequences" hints
//        at multi-chain thinking — separate chains could
//        each have their own number space (Q4).
//
// --- Q4 (2026-05-30): Multiple chains ---
// Q: Is the sequence number a single global pool (one chain
//    only — numbers 1-N across the whole library) or can
//    there be multiple independent chains (chain A = 1-5,
//    chain B = 11-15, user picks which chain to start)?
//    Single chain is simpler — one column on TimerData.
//    Multiple chains needs a chainID/chainName column to
//    group presets, then sequenceNumber is unique within
//    each chain. Your "multiple sequences" phrasing in Q3
//    suggests you're already thinking multi-chain.
// A: Michael 2026-05-30 (first pass): "i think we should stay
//    focused and limit it to one chain of events"
//    Michael 2026-05-30 (future-growth context, immediate
//    follow-up): "in the future maybe we have seven chains
//    then we have 31 chains and eventually we can have up
//    to 365"
//    The numbers map to time cycles: 7 = days of week (one
//    chain per weekday), 31 = days of month, 365 = days of
//    year. Vision: a different chain per day, ultimately
//    one chain per calendar day.
//    DECISION:
//      • v1.0 ships with a single chain — Unix focus,
//        simplest UX, smallest surface to perfect
//      • Data model for v1.0: TimerData.sequenceNumber: Int?
//        (nil = standalone, non-nil = in the one chain)
//      • Multi-chain expansion is a FUTURE roadmap item —
//        when it lands, the schema migration adds a chainID
//        column (likely keyed by a calendar concept like
//        weekday-name or date) and sequenceNumber becomes
//        unique within each chain
//      • Don't add the chainID column now — carrying unused
//        fields anticipates future complexity. Migration
//        when the feature ships.
//
// --- Q5 (2026-05-30): Mid-chain interruption ---
// Q: You're in the middle of Work=1 (running, 2 hours in of
//    4). You manually tap Stop. What happens to the chain —
//    does the whole chain abort (Break=2 never fires),
//    pause (Break is queued and resumes when you tap Start
//    again), or skip to next (Break=2 starts immediately)?
// A: Michael 2026-05-30: "maybe midchain interuption can be
//    a pause or even an abort of the whole chain depending
//    on the either choosing a pause button or a stop button?"
//    DECISION:
//      • Two distinct controls in the running state:
//          - PAUSE — freeze the current preset; chain stays
//            alive. Tap Resume to continue where left off.
//            AlarmKit alarm cancelled on pause, rescheduled
//            with remaining time on resume.
//          - STOP — abort the whole chain. Current preset
//            ends. Subsequent presets in the chain do NOT
//            fire. Runtime returns to READY.
//      • Button row updates: when running, show PAUSE and
//        STOP. When paused, show RESUME and STOP. When
//        ready, show START.
//      • TimerRuntime status enum gains a paused state
//        (so the chain knows whether it's "between presets,
//        chain alive" vs "fully stopped").
//
//    Michael 2026-05-30 (follow-up, expanding the control
//    set): "we could have something equivilant to a media
//    player play pause stop next track previous track the
//    tracks would be the timers"
//    EXTENDED DECISION — full media-transport control set:
//      • PLAY    — start the active preset (or start the
//                  chain from the first sequence number)
//      • PAUSE   — freeze current preset, chain alive
//      • STOP    — abort the chain entirely
//      • NEXT    — skip to next preset in the chain
//                  (cancel current AlarmKit, jump forward)
//      • PREVIOUS — skip to previous preset in the chain
//                  (cancel current, jump back)
//      The metaphor maps cleanly: tracks = presets in the
//      chain, transport buttons act on the chain just like
//      a media player acts on a playlist.
//      SF Symbol set: play.fill, pause.fill, stop.fill,
//      forward.fill, backward.fill.
//      Standalone presets (not in a chain) — NEXT/PREVIOUS
//      are greyed out or hidden since there's no chain to
//      navigate.
//
// --- Q6 (2026-05-30): Sound vs action layering ---
// Q: How do alarm sound and Shortcut/webhook action layer
//    against each other — is sound per-preset, app-level,
//    or both?
// A: Michael 2026-05-30: "top level setting would be an
//    alarm sound the webhook or shortcut would be configured
//    in each timers action setting"
//    DECISION:
//      • Sound = app-level (one sound for the whole app,
//        used by every preset's alarm). Lives in app
//        settings (UserDefaults or AppSettings @Model).
//        Two sources: built-in ringtone bank or user-imported
//        audio file.
//      • Action (Shortcut or webhook) = per-preset. Each
//        preset's editor has its own action fields.
//
// --- Q7 (2026-05-30): Action firing timing ---
// Q: For presets that have a Shortcut/webhook configured,
//    when does it fire — immediately when the alarm rings
//    (background, even if you're away from the device) or
//    only when you tap Stop on the system alert (foreground
//    return)?
// A: Michael 2026-05-30: "the event is fired at the
//    conclusion of the timer"
//    DECISION:
//      • Background fire — the action runs at the moment
//        the timer hits zero (= when AlarmKit's alarm rings).
//        No need for the user to be in the app or to
//        acknowledge the alert.
//      • Implementation: AlarmKit's alarm-fired handler
//        triggers the action firing. Request a
//        beginBackgroundTask to extend background time if
//        the webhook is slow. Shortcuts via App Intent run
//        in their own process so background time is less of
//        a concern.
//      • Side benefit: this is what makes HA automations
//        actually useful — lights / scenes / music change
//        when the timer ends, regardless of where you are.
//
// --- Q9 (2026-05-30): Chain advance gated on alarm ack? ---
// Q (Michael, raised 2026-05-30): "if an event or timer is
//    in a timmer complete state i am wondering if the chain
//    should continue wether or not the alarm anunciation has
//    been confirmed by the user or should be in a pause
//    state untill the alarm state has been cleared."
//    Two paths:
//    A. Continue on completion — chain advances immediately
//       when timer N completes; timer N+1 begins counting
//       down regardless of whether user dismissed N's alarm.
//       Good for passive / fire-and-forget routines (HA
//       scene changes that happen on schedule).
//    B. Pause until acknowledged — chain WAITS at completion
//       of N until user dismisses N's system alert; only
//       then does N+1 begin. Good for routines that require
//       engagement (work/break — you should have to actually
//       engage to advance).
//    C. Per-preset toggle — each preset chooses its own
//       gating behavior. Most flexible, adds an editor field.
// A: Michael 2026-05-30 (first pass): "i know we can do what
//    the iphone notifications does, it lets the iphone owner
//    set the notifications to passive or persistant"
//    Michael 2026-05-30 (refinement): "how about per timer is
//    a persistant toggle so if the persistant is toggled on
//    the timer waits for recognition from the user before
//    releasing focus to go to the next timer"
//    DECISION:
//      • Per-preset toggle: isPersistent: Bool
//        - true  = timer waits for user recognition of the
//                  alarm before releasing focus to the next
//                  preset in the chain (persistent)
//        - false = chain advances immediately on timer
//                  complete; alarm appears briefly without
//                  gating advance (passive)
//      • Default: true (persistent). Safer default — assumes
//        engagement unless explicitly opted out.
//      • Editor surfaces it as a Persistent toggle. iOS
//        notification UX uses the same vocabulary so users
//        already know what it means.
//
// --- Q8 (2026-05-30): Multiple actions per preset ---
// Q: Can a preset fire BOTH a webhook AND a Shortcut on the
//    same complete, or just one of the two (radio choice)?
//    Multiple is more flexible; one keeps the editor tidy.
// A: Michael 2026-05-30: "one or the other for now"
//    DECISION:
//      • Mutually exclusive — a preset configures EITHER a
//        webhook OR a Shortcut, not both. Editor uses a
//        radio-style picker.
//      • TimerData.actionKind: enum {none, shortcut, webhook}
//        already captures this (only one non-none value at
//        a time).
//      • "for now" — future could expand to allow both;
//        v1 stays radio-choice for editor simplicity.
//
// --- Q10 (2026-05-30): Factory default presets ---
// Q: First-launch experience — empty library + "+ Add your
//    first timer" prompt, or ship with starter presets
//    (Work/Break/Stretch) already in place so the user can
//    run the chain immediately?
// A: Michael 2026-05-30: sample presets are an OPTION in
//    the Settings sheet — the user can opt in to load them,
//    not auto-populated on first launch.
//    DECISION:
//      • App opens to an empty library on first launch
//        ("+ Add your first timer" empty state)
//      • Settings sheet has a "Load sample presets" button
//      • Tapping it adds the canonical Work / Break /
//        Stretch chain to the user's library
//      • Idempotency — Michael 2026-05-30 (immediate
//        follow-up): "the example choice only repopulates
//        missing examples it doesnt auto add example times
//        multiple times"
//        DECISION: each canonical sample has a deterministic
//        UUID. On tap, check the library for each sample's
//        UUID — add the missing ones, skip ones already
//        present. User can delete samples and re-tap to
//        restore only the deleted ones; nothing duplicates.
//      • The sample library acts as a teaching tool — shows
//        the chain feature working without forcing it on
//        users who already know what they want.
//
// --- Q11 (2026-05-30): watchOS support ---
// Q: Project currently supports iPhone, iPad, Mac, visionOS
//    but not watchOS. Add a watchOS target now, leave it for
//    later, or skip entirely?
// A: Michael 2026-05-30: "i am no lomger a watch os
//    proponent, i have turned to pebble os"
//    DECISION:
//      • No watchOS target — not now, not on the roadmap.
//      • Pebble OS interest is parking-lot context, not a
//        v1 platform for this app.
//      • SUPPORTED_PLATFORMS stays at iphoneos /
//        iphonesimulator / macosx / xros / xrsimulator.
//      • Broader preference saved in apartment memory: don't
//        suggest watchOS as a platform for future projects.
//
// --- Q12 (2026-05-30): Visual identity ---
// Q: What's the look — system default (familiar, ships fast,
//    adapts to user's iOS appearance), an amber CRT mode
//    (Hercules / monochrome aesthetic distinctive to
//    Michael), customizable theme (user picks color), or
//    something else?
// A: Michael 2026-05-30: "system defaults"
//    DECISION:
//      • Use system semantic colors and fonts throughout.
//        No custom theme system, no color picker, no amber
//        CRT mode, no user-customizable chrome.
//      • Cards: .thinMaterial fill, system rounded
//        corners, .primary numerals, system semantic colors
//        for status (.green/.red/.orange) as appropriate.
//      • App icon: simple, no amber-CRT lineage.
//      • Dark/Light mode handled by iOS — no app-side toggle.
//      • Ships fastest, looks native, ages well with iOS
//        design updates.
//
// --- Q13 (2026-05-30): App Store pricing ---
// Q: Free, 99¢, $1.99 / $2.99 / $4.99 one-time paid,
//    freemium, or subscription?
// A: Michael 2026-05-30 (initial): "you should always assume
//    it is a paid app and not a free app you should assume
//    the cost of the app is 100.00 or more"
//    Michael 2026-05-30 (refinement): "its not a one time
//    fee its is a reoccuring fee so you dont get complaicent"
//    DECISION:
//      • Paid app, premium positioning, RECURRING
//        subscription model — not a one-time purchase.
//      • Price tier: $100.00 or more. Exact pricing details
//        (cadence, dollar amount, IAP tiers, App Store
//        pricing tier number) are Michael's lane to
//        configure in App Store Connect.
//      • Reasoning for recurring: the ongoing revenue
//        forces continued shipping/improvements. Michael's
//        anti-complacency mechanic.
//      • Implication for design: every shipped feature
//        must clear a premium-app capability bar AND each
//        release cycle must add enough value to justify
//        the continued subscription.
//      • Implication for marketing copy: capability-led
//        voice, not bargain-led. App Store description and
//        screenshots should communicate why this is worth
//        the recurring premium tag.
//      • Implication for verification: thorough — premium
//        apps don't ship with crash bugs or first-run
//        confusion.
//      • Broader rule saved to apartment memory: assume
//        paid + recurring + $100+ as the default for any
//        Michael app unless otherwise specified.
//
// --- Q14 (2026-05-30): Gap-within-chain behavior ---
// Q: Q2 covered end-of-chain (chain ends when next slot is
//    empty). What about gaps INSIDE the chain — say timers
//    are numbered 1, 3, 5 (skipping 2 and 4)? When timer 1
//    finishes, does the chain look for the next-higher
//    present number (1 → 3 → 5 → end), or does the missing
//    slot end the chain (1 → end)?
// A: Michael 2026-05-30: "i think there should be some sort
//    of mechanism so they tap the next sequence number
//    available so they dont repeat or skip numbering"
//    DECISION:
//      • UI prevents gaps at creation. The sequence number
//        picker auto-suggests the next-available contiguous
//        number (if 1, 2, 3 exist, picker offers 4).
//      • UI prevents ties too (reinforces Q3 — picker hides
//        already-used numbers).
//      • On deletion: auto-compact — when user deletes the
//        preset at sequence N, presets at N+1, N+2, ...
//        shift down to fill the gap. Gaps never exist in
//        the live library, only momentarily during the
//        deletion transaction.
//      • Runtime needs no gap-handling logic — by
//        construction, sequence numbers are always
//        contiguous 1...N.
//
// --- Q15 (2026-05-30): Standalone (non-chain) presets ---
// Q: Do all saved presets have to be in the chain (every
//    preset gets a sequence number, fits in the 1...N
//    order), or can a preset exist outside the chain as a
//    one-off (no sequence number, run independently)?
// A: Michael 2026-05-30: "it can exist but it woould be
//    ignored and not be part of the sequence. it wouldnt
//    be disabled either. if there is a one off the user has
//    to manually press start for that extra one off timer"
//    DECISION:
//      • Standalone presets exist as first-class citizens
//        (sequenceNumber: nil = standalone, non-nil = in
//        the chain).
//      • Standalones are visible in the preset list, not
//        hidden, not disabled.
//      • Chain runtime IGNORES standalones — only walks
//        numbered presets in sequence.
//      • To use a standalone, user taps it directly and
//        presses Play. No auto-advance from a standalone
//        (it runs alone, completes, done).
//      • TimerData.sequenceNumber: Int? confirmed as the
//        data shape (nullable).
//      • List placement: Michael 2026-05-30 (follow-up):
//        "i think it should be an overiding sequence number
//        in a field 1,2,3,4,etc and not in alphabetical
//        order of timer name"
//        DECISION: list view sorts by sequenceNumber ASC,
//        with NULLs (standalones) at the end. Chain presets
//        appear first in numeric order (1, 2, 3, ...);
//        standalones appear after, secondary-sorted by
//        createdDate (or another stable key — never by
//        name alphabetically).
//
// --- Q16 (2026-05-30): User-imported audio sources ---
// Q: For the custom audio track option (user-provided
//    alarm sound), which sources should be supported —
//    Files only, Files + Music library, or also Voice
//    Memos?
// A: Michael 2026-05-30: "file picker or apple music/
//    personal library"
//    DECISION:
//      • Two import sources supported:
//        1. Files (UIDocumentPicker / .fileImporter) —
//           free-form, covers iCloud Drive, Dropbox, any
//           audio file the user has access to
//        2. Apple Music / personal library (MusicKit) —
//           Apple Music streaming + iTunes purchases +
//           user's synced music library
//      • Voice Memos NOT a source for v1.
//      • Entitlements / Info.plist needed:
//        - Files: no special entitlement (system-managed)
//        - Music: NSAppleMusicUsageDescription with a
//          clear explanation string ("Pick a song from
//          your library to use as an alarm sound")
//      • Edge case: Apple Music streaming tracks require
//        active subscription for playback — if the user
//        loses Apple Music access, the alarm sound will
//        fail. Need graceful fallback (system alarm
//        sound).
//      • Edge case: file-picked audio uses security-
//        scoped URL — bookmark must be persisted so
//        playback works after app relaunch.
//
// --- Q17 (2026-05-30): Built-in (bundled) ringtone bank ---
// Q: Should the app ship with its own bundled ringtone bank
//    (curated sounds the user can pick without importing),
//    and if so what character?
// A: Michael 2026-05-30: "we cant include bundled ringtones
//    because i dont have lisencing connections"
//    DECISION:
//      • No bundled ringtone bank.
//      • Default alarm sound = AlarmKit's system-provided
//        default (the sound that plays when no custom
//        audio is specified by the user).
//      • All non-default alarm sounds come from user-
//        imported content (Files / Music library per Q16).
//      • Broader rule saved to apartment memory: don't
//        propose bundling audio assets in any Michael app
//        — no licensing connections, only system defaults
//        or user-imported content.
//
// --- Q18 (2026-05-30): Subscription cadence ---
// Q: Q13 settled recurring + $100+. What's the billing
//    period — monthly, annual, or both?
// A: Michael 2026-05-30: "dont worry about billing, that is
//    not in your wheelhouse and is above your paygrade"
//    DECISION: lane boundary acknowledged. Pricing details
//    (cadence, dollar amount, IAP tiers, App Store pricing
//    tier number) are Michael's lane to configure in App
//    Store Connect. Design lane (quality, capability,
//    polish) is Claude's. Don't ask billing-detail
//    questions; just design for premium tier.
//
// --- Q19 (2026-05-30): Completion log / history ---
// Q: Should the app keep a record of past completions for
//    streak / stats / most-used surfaces, or skip it?
// A: Michael 2026-05-30: "log yes, it probably should be
//    like a console i think if you delete and reinstall the
//    app the log is reset"
//    DECISION:
//      • Keep a completion log.
//      • UI shape: console-style (likely monospaced font,
//        one event per line, chronological — like a system
//        log, not a fancy stats dashboard).
//      • Local-only storage. Not synced via CloudKit. On
//        delete + reinstall the log resets.
//      • Implementation: separate SwiftData ModelContainer
//        without CloudKit config, holding a CompletionEntry
//        @Model. The existing CloudKit-backed container
//        holds only TimerData (preset library); this new
//        local container holds completion history.
//      • Console direction: newest at TOP (resolved
//        2026-05-30 via roadmap HTML line 200).
//      • Retention: rolling 1 day OR 1000 entries, whichever
//        cap hits first; oldest trimmed when either limit
//        is exceeded (resolved 2026-05-30 via roadmap line
//        201).
//      • Clear-log option in Settings sheet: "Clear log"
//        button with destructive-action confirmation alert
//        (resolved 2026-05-30 via roadmap line 202).
//      • Entry fields: timestamp, preset-name-snapshot
//        (so display survives preset rename or delete),
//        duration completed, was-in-chain flag (resolved
//        2026-05-30 via roadmap line 203).
//      Q19 fully resolved.
//
// --- Q20 (2026-05-30): Sharing presets between users ---
// Q: Portable file format (.timermod), AirDrop, QR, share-
//    link URL — should users be able to share presets out
//    to other users?
// A: Michael 2026-05-30: "i dont think so, i dont see the
//    need"
//    DECISION:
//      • No sharing surface in v1.
//      • No portable file format, no UTI registration, no
//        share sheet integration, no QR / URL share-link.
//      • Presets live in the user's own library only.
//        CloudKit syncs them across the user's own devices,
//        but not to other users.
//      • Simplifies scope significantly — no export/import
//        flow, no file format spec, no document-based-app
//        wiring needed.
//
// --- Q21 (2026-05-30): Categories / tags on presets ---
// Q: Should presets carry a category or tag field (Work,
//    Health, Cooking, etc.) for filtering / grouping /
//    color-coding in large libraries?
// A: Michael 2026-05-30: "i dont see the need"
//    DECISION:
//      • No categories or tags on TimerData.
//      • The chain ordering + standalone bucket provide
//        sufficient organization.
//      • Keeps the editor and list view clean.
//
// --- Q22 (2026-05-30): Alarm UX extras + unified action ---
// Q (initially): Beyond the basic ring, what else —
//    escalating volume, custom haptics, vibration-only
//    mode, or just what AlarmKit gives?
// A (initial): Michael 2026-05-30: "alarm kit provides or
//    what the action field has (webhook audio file or
//    whatever)"
//    Michael 2026-05-30 (refinement): "the actions field or
//    what ever we had earlier was where you had the file
//    picker or the webhook or now what ever allarmkit
//    provides"
//    DECISION — UNIFIED ACTION MODEL (revises Q6 + Q8):
//      • The previous separation of "app-level sound" (Q6)
//        and "per-preset action of webhook/shortcut" (Q8)
//        is collapsed into ONE per-preset action picker.
//      • Per preset, exactly one of these four:
//          1. AlarmKit default — system alarm sound, no
//             custom audio, no webhook, no Shortcut. Just
//             the OS-provided ring.
//          2. File picker — user-imported audio file plays
//             at completion (replaces the AlarmKit sound).
//             Sources per Q16: Files + Apple Music /
//             personal library.
//          3. Webhook — HTTP request fires at completion
//             (no custom sound; uses AlarmKit default ring
//             alongside).
//          4. Shortcut — named Apple Shortcut runs at
//             completion (no custom sound; uses AlarmKit
//             default ring alongside).
//      • No app-side escalating volume, custom haptics, or
//        vibration-only mode. If a user wants those, they
//        configure a Shortcut or webhook receiver to do it.
//      • TimerData.actionKind: enum {alarmKitDefault,
//        audioFile, webhook, shortcut}.
//      • Q6 (app-level sound) and Q8 (radio webhook/
//        shortcut) — SUPERSEDED by this. The action field
//        is now the single per-preset surface for
//        configuring what happens at completion.
//
// --- Q23 (2026-05-30): visionOS support ---
// Q: Project currently lists visionOS in SUPPORTED_PLATFORMS
//    (xros / xrsimulator) and TARGETED_DEVICE_FAMILY="1,2,7"
//    by Xcode universal-template default. Keep it as a
//    supported platform or strip it?
// A: Michael 2026-05-30 (initial): "im not interested in
//    visionos, i never try the vision os simulator, if it
//    works or not in vision os i dont care"
//    Michael 2026-05-30 (clarification): "im not saying
//    exclude vision os im just saying if it works in vision
//    os bonus, if it doesnt then im not loosing sleep"
//    Michael 2026-05-30 (reasoning): "if it works on an ipad
//    it is supposed to work on an m series mac or vision os"
//    Background: Apple's iPad-app-compatibility layer runs
//    iPad apps on M-series Macs and Apple Vision Pro for
//    free — if the iPad build works, those two platforms
//    get it as a bonus with no extra build/test work.
//    DECISION:
//      • Don't strip visionOS — leave it in from Xcode
//        universal template (SUPPORTED_PLATFORMS still
//        xros/xrsimulator, TARGETED_DEVICE_FAMILY still
//        "1,2,7").
//      • Don't actively test in visionOS simulator.
//      • Don't make marketing claims about visionOS
//        support in App Store description / screenshots.
//      • Ships as bonus-territory: if it works, great; if
//        it doesn't, not a fire to fight.
//      • Roadmap intentionally has no visionOS-tailored
//        affordances (floating-window optimizations,
//        spatial placement, etc.) — universal layout only.
//
// --- Q24 (2026-05-30): Per-preset optional date ---
// Q: A targetDate field on TimerData — optional. What's it
//    for? Auto-schedule, label metadata, filter/grouping,
//    or something else?
// A: Michael 2026-05-30: "no date needed but if the user
//    declares a date that date is persistant"
//    Michael 2026-05-30 (clarification): "you cant auto
//    schedule because the timer could become stale. if the
//    user does not declare a date no date is involved, if
//    the user choses a date it becomes persistant"
//    Michael 2026-05-30 (chain constraint): "actually if it
//    has a date then its a one off timer and cant be
//    included in the sequence of timers"
//    DECISION:
//      • TimerData.targetDate: Date? — optional, nullable.
//      • nil = no date involved; preset is eligible for the
//        chain (sequenceNumber can be set).
//      • Non-nil = ONE-OFF preset; sequenceNumber MUST be
//        nil. Dated and chained are mutually exclusive.
//      • Invariant: targetDate != nil → sequenceNumber == nil
//      • UI enforces the constraint — assigning a date
//        clears any existing sequenceNumber and hides the
//        sequence picker; assigning a sequenceNumber clears
//        any existing date and hides the date picker.
//      • When date is set, it persists on the preset (synced
//        via CloudKit alongside the rest).
//      • NO auto-fire — Michael's reasoning: timers can go
//        stale (user changes mind, phone off, network out
//        at the scheduled moment, etc.). Calendar-based
//        firing is rejected.
//      • Visible on the preset row in the list (e.g.
//        "Doctor appointment — 2026-06-15").
//      • Open follow-up: how prominently is it shown in the
//        list — date as inline text, separate column, or
//        chip badge?
//
// ============================================================
// WIKI SYNC
// ============================================================
//
// This file is the source of truth. After every meaningful
// edit, mirror to the project's GitHub wiki at
// Developer-Notes.md. Wiki not yet initialized on this repo —
// sync starts after first substantive content lands.
//
// ============================================================
// MILESTONE SEQUENCE
// ============================================================
//
//   v0.0 — Xcode project + Widget Extension target + this
//          DeveloperNotes file populated. (Done 2026-05-30.)
//   v0.1 — Item.swift → TimerData.swift; Schema updated;
//          project still builds.
//   v0.2 — AlarmKitManager; first Start triggers auth;
//          alarm rings on physical iPhone.
//   v0.3 — TimerRuntime @Observable wired into environment.
//   v0.4 — TimerView card (notation, duration picker, mode,
//          status, numerals, button row, note inline).
//   v0.5 — PresetListView (sidebar on iPad/Mac, sheet on
//          iPhone); active-preset switching.
//   v0.6 — EditorSheet with full TimerData field set (action
//          picker, persistent toggle, sequence).
//   v0.7 — Sequence chain runtime (auto-advance, end-at-
//          empty-slot, no-tie / no-gap UI).
//   v0.8 — Action firing (audioFile / webhook / shortcut
//          paths wired into completion handler).
//   v0.9 — CompletionEntry @Model + console log view.
//   v0.10 — Settings sheet + "Load sample presets" action.
//   v0.11 — iCloud container provisioned; CloudKit sync
//          verified between two devices.
//   v0.12 — App Group entitlement + snapshot publisher in
//          main app writing active-preset snapshot.
//   v0.13 — Home Screen widget — real countdown view reading
//          from App Group snapshot.
//   v0.14 — Live Activity — real preset name + remaining
//          numerals (Lock Screen + Dynamic Island).
//   v0.15 — Control Center widget StartTimerIntent wired
//          to actually toggle the selected preset.
//   v0.16 — Accessibility pass (VoiceOver labels, Dynamic
//          Type verification).
//   v0.17 — Privacy Manifest (PrivacyInfo.xcprivacy) +
//          nutrition labels.
//   v0.18 — App icon + App Store screenshots (per platform).
//   v0.19 — App Store Connect record + marketing copy +
//          support URL page.
//   v1.0 — App Store submission.
//
// Review surface for this roadmap (status badges, line
// numbers, auto-refresh every 60s) lives in the apartment
// Workshop folder; opened separately for Michael to react
// to and lock items in.
//
