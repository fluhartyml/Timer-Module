//
//  ContentView.swift
//  Timer Module
//
//  Created by Michael Fluharty on 5/30/26.
//
//  v0.1 placeholder. The real single-timer card (TimerView)
//  arrives at v0.4. For now this just confirms the TimerData
//  schema works end-to-end (insert, fetch, display, delete).
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TimerData.createdDate, order: .reverse) private var presets: [TimerData]

    var body: some View {
        NavigationStack {
            Group {
                if presets.isEmpty {
                    ContentUnavailableView(
                        "Add your first timer",
                        systemImage: "timer",
                        description: Text("Or tap Settings → Load sample presets")
                    )
                } else {
                    List {
                        ForEach(presets) { preset in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.notation.isEmpty ? "Untitled" : preset.notation)
                                    .font(.headline)
                                Text("\(preset.durationSeconds)s • \(preset.mode.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete(perform: deletePresets)
                    }
                }
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

    private func deletePresets(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(presets[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TimerData.self, inMemory: true)
}
