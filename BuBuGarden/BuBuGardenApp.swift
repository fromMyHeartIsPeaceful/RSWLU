import SwiftUI

@main
struct BuBuGardenApp: App {
    @StateObject private var store = GardenStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .task {
                    await store.refreshStepsIfPossible()
                }
        }
    }
}
