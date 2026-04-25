// AddWaterIntent.swift — Widget Extension target (iOS 17+)
//
// AppIntent that handles the "+" button tap in the widget.
// Adds the default portion to daily intake and reloads the widget timeline.

import AppIntents
import WidgetKit

/// AppIntent triggered when the user taps the "+" button in the widget.
/// Reads the current default portion from shared AppGroup storage,
/// adds it to the daily intake, and requests a widget timeline reload.
struct AddWaterIntent: AppIntent {

    static var title: LocalizedStringResource = "Add water portion"

    func perform() async throws -> some IntentResult {
        // Read current values from shared AppGroup storage
        let store = AppGroupStore.shared
        // Add the default portion to today's intake
        store.addPortion(store.defaultPortion)
        // Reload widget timeline so the UI updates immediately
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
