import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(BiometricGate.self) private var gate
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = PatientListViewModel()

    var body: some View {
        ZStack {
            Color.surgBackground
                .ignoresSafeArea()

            if !appState.hasAcceptedDisclaimer {
                DisclaimerView()
            } else if gate.isEnabled && gate.isLocked {
                LockScreenView()
            } else {
                NavigationStack {
                    PatientListView(viewModel: viewModel)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background, .inactive:
                gate.lock()
            case .active:
                if gate.isLocked {
                    Task { _ = await gate.unlock() }
                }
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Lock Screen

private struct LockScreenView: View {
    @Environment(BiometricGate.self) private var gate

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.surgAccent)

            Text("SurgSign is locked")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.surgText)

            Text("Authenticate to view patient data.")
                .font(.subheadline)
                .foregroundStyle(Color.surgTextSecondary)
                .multilineTextAlignment(.center)

            Button {
                Task { _ = await gate.unlock() }
            } label: {
                Label("Unlock", systemImage: "faceid")
                    .font(.headline)
                    .frame(maxWidth: 220)
                    .padding(.vertical, 12)
                    .background(Color.surgAccent, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.black)
            }
            .padding(.top, 8)
        }
        .padding(40)
    }
}