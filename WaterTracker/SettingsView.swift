// SettingsView.swift — Settings screen of the WaterTracker app
//
// Allows the user to update the daily goal and default portion size.
// Displays validation errors inline and shows current values in an info section.

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var waterStore: WaterStore

    @State private var goalText = ""
    @State private var portionText = ""

    var body: some View {
        NavigationStack {
            Form {

                // MARK: Daily goal section
                Section("Dzienny cel (ml)") {
                    TextField("np. 2000", text: $goalText)
                        .keyboardType(.numberPad)

                    if let err = waterStore.goalError {
                        Text(err)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }

                    Button("Zapisz cel") {
                        if let value = Int(goalText) {
                            waterStore.saveDailyGoal(value)
                        }
                    }
                    .disabled(Int(goalText) == nil)
                }

                // MARK: Default portion section
                Section("Domyślna porcja (ml)") {
                    TextField("np. 250", text: $portionText)
                        .keyboardType(.numberPad)

                    if let err = waterStore.portionError {
                        Text(err)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }

                    Button("Zapisz porcję") {
                        if let value = Int(portionText) {
                            waterStore.saveDefaultPortion(value)
                        }
                    }
                    .disabled(Int(portionText) == nil)
                }

                // MARK: Info section
                Section("Informacje") {
                    LabeledContent("Aktualny cel", value: "\(waterStore.dailyGoal) ml")
                    LabeledContent("Domyślna porcja", value: "\(waterStore.defaultPortion) ml")
                }
            }
            .navigationTitle("Ustawienia")
            .onAppear {
                // Pre-fill text fields with current stored values
                goalText    = "\(waterStore.dailyGoal)"
                portionText = "\(waterStore.defaultPortion)"
            }
        }
    }
}
