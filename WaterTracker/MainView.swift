// MainView.swift — Main screen of the WaterTracker app
//
// Displays daily intake progress, quick-add controls, and a toolbar
// button that opens SettingsView as a sheet.

import SwiftUI

// MARK: - Main View

struct MainView: View {
    @EnvironmentObject var waterStore: WaterStore

    @State private var customPortionText = ""
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                // Informational banner shown when App Group is unavailable
                if !AppGroupStore.shared.isAppGroupAvailable {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                        Text("Dane lokalne — App Group niedostępny")
                    }
                    .foregroundStyle(.orange)
                    .font(.footnote)
                    .padding(.horizontal)
                }

                ProgressSection(
                    intake: waterStore.dailyIntake,
                    goal: waterStore.dailyGoal,
                    progress: waterStore.progress,
                    isGoalReached: waterStore.isGoalReached
                )

                QuickAddSection(
                    defaultPortion: waterStore.defaultPortion,
                    customPortionText: $customPortionText,
                    onAddDefault: {
                        waterStore.addPortion(waterStore.defaultPortion)
                    },
                    onAddCustom: {
                        waterStore.addPortion(Int(customPortionText) ?? 0)
                        customPortionText = ""
                    },
                    onUndo: {
                        waterStore.subtractLastPortion()
                    }
                )
            }
            .padding()
            .navigationTitle("WaterTracker")
            .toolbar {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(waterStore)
            }
            .onAppear {
                waterStore.checkAndResetIfNewDay()
            }
        }
    }
}

// MARK: - Progress Section

/// Displays the current intake vs. goal, a progress bar, and a completion badge.
private struct ProgressSection: View {
    let intake: Int
    let goal: Int
    let progress: Double
    let isGoalReached: Bool

    var body: some View {
        VStack(spacing: 12) {
            Text("\(intake) / \(goal) ml")
                .font(.title2)
                .fontWeight(.semibold)

            ProgressView(value: progress)
                .tint(isGoalReached ? .green : .blue)
                .scaleEffect(x: 1, y: 2, anchor: .center)

            if isGoalReached {
                Label("Cel osiągnięty!", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Quick Add Section

/// Provides buttons for adding the default portion, a custom portion, and undoing the last entry.
private struct QuickAddSection: View {
    let defaultPortion: Int
    @Binding var customPortionText: String
    let onAddDefault: () -> Void
    let onAddCustom: () -> Void
    let onUndo: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Default portion button
            Button(action: onAddDefault) {
                Label("+\(defaultPortion) ml", systemImage: "drop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            // Custom portion input
            HStack {
                TextField("Własna porcja (ml)", text: $customPortionText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)

                Button("Dodaj", action: onAddCustom)
                    .buttonStyle(.bordered)
                    .disabled(Int(customPortionText) == nil)
            }

            // Undo last entry
            Button("Cofnij ostatnią", action: onUndo)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
