import SwiftUI
import SwiftData

@main
struct SurgSignApp: App {
    @State private var appState = AppState()
    @State private var biometricGate = BiometricGate()
    @State private var purgePolicy = PurgePolicy()

    private let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(biometricGate)
                .environment(purgePolicy)
                .modelContainer(persistence.container)
                .task {
                    purgePolicy.registerLifecycleHooks(controller: persistence)
                    purgePolicy.checkAndPurgeIfNeeded(controller: persistence)
                }
        }
    }
}