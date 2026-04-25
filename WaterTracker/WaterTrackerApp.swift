// WaterTrackerApp.swift — App entry point
//
// Defines the @main struct conforming to App protocol.
// Creates a single WaterStore instance and injects it into the environment.

import SwiftUI

@main
struct WaterTrackerApp: App {

    /// Shared view model injected into the entire view hierarchy.
    @StateObject private var waterStore = WaterStore()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(waterStore)
        }
    }
}
