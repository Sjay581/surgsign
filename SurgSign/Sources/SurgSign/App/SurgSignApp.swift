import SwiftUI
import SwiftData

@main
struct SurgSignApp: App {
    let appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .modelContainer(for: [Patient.self, PatientTask.self])
        }
    }
}
