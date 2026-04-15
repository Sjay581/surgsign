import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = PatientListViewModel()

    var body: some View {
        ZStack {
            Color.surgBackground
                .ignoresSafeArea()

            if appState.hasAcceptedDisclaimer {
                NavigationStack {
                    PatientListView(viewModel: viewModel)
                }
            } else {
                DisclaimerView()
            }
        }
        .preferredColorScheme(.dark)
    }
}
