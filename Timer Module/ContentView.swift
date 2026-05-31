//
//  ContentView.swift
//  Timer Module
//
//  v0.4 — wraps the TimerView card. Active-preset selection arrives
//  at v0.5 (PresetListView); for now defaults to the first preset
//  in the library so the card has something to show.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TimerRuntime.self) private var runtime
    @Query(sort: \TimerData.createdDate, order: .reverse) private var presets: [TimerData]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    TimerView(preset: currentPreset)
                        .padding(.horizontal)

                    // Placeholder preset list — replaced by PresetListView at v0.5
                    if !presets.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Library")
                                .font(.headline)
                                .padding(.horizontal)
                            ForEach(presets) { preset in
                                presetRow(preset)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        runtime.activePresetId = preset.id
                                    }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Timer Module")
            .toolbar {
                ToolbarItem {
                    Button(action: addPlaceholder) {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
        }
    }

    private var currentPreset: TimerData? {
        if let activeId = runtime.activePresetId,
           let match = presets.first(where: { $0.id == activeId }) {
            return match
        }
        return presets.first
    }

    private func presetRow(_ preset: TimerData) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(preset.notation.isEmpty ? "Untitled" : preset.notation)
                    .font(.body.weight(.medium))
                if !preset.note.isEmpty {
                    Text(preset.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text("\(preset.durationSeconds)s")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private func addPlaceholder() {
        withAnimation {
            let now = Date()
            let newPreset = TimerData(
                notation: "Timer \(presets.count + 1)",
                note: "",
                mode: .countDown,
                durationSeconds: 300
            )
            newPreset.createdDate = now
            newPreset.updatedDate = now
            modelContext.insert(newPreset)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TimerData.self, inMemory: true)
        .environment(TimerRuntime.shared)
}
