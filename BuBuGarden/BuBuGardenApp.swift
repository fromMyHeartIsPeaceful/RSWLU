import SwiftUI

@main
struct BuBuGardenApp: App {
    @StateObject private var store = GardenStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .task {
                    await store.refreshStepsIfPossible()
                    store.startStepObservationIfPossible()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task {
                        await store.refreshStepsIfPossible()
                        store.startStepObservationIfPossible()
                    }
                }
        }
    }
}
