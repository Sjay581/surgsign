import SwiftUI
import SwiftData

struct PatientListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var patients: [Patient]
    @Bindable var viewModel: PatientListViewModel

    @State private var isEditingServiceName = false
    @State private var showingSettings = false
    @FocusState private var serviceNameFieldFocused: Bool

    var body: some View {
        ZStack {
            Color.surgBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                if viewModel.filteredPatients(patients).isEmpty {
                    EmptyStateView()
                        .frame(maxHeight: .infinity)
                } else {
                    patientList
                }

                bottomToolbar
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showingAddForm) {
            PatientFormView()
        }
        .sheet(item: $viewModel.editingPatient) { patient in
            PatientFormView(patient: patient)
        }
        .sheet(isPresented: $viewModel.showingHandoff) {
            HandoffView()
        }
        .fullScreenCover(isPresented: $viewModel.showingScanner) {
            ScanView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .confirmationDialog(
            "Delete Patient",
            isPresented: $viewModel.showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let patient = viewModel.patientToDelete {
                    viewModel.deletePatient(patient, context: modelContext)
                }
            }
            Button("Cancel", role: .cancel) {
                viewModel.patientToDelete = nil
            }
        } message: {
            if let patient = viewModel.patientToDelete {
                Text("Are you sure you want to remove \(patient.name) from the list? This cannot be undone.")
            }
        }
        .onAppear {
            viewModel.seedDemoDataIfNeeded(context: modelContext)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    serviceNameRow
                    Text(Date().displayString)
                        .font(.subheadline)
                        .foregroundStyle(Color.surgTextSecondary)
                }

                Spacer()

                ShiftToggleView()

                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundStyle(Color.surgTextSecondary)
                        .padding(8)
                        .background(Color.surgSurface, in: Circle())
                }
                .accessibilityLabel("Settings")
            }

            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.surgTextSecondary)

                    TextField("Search patients...", text: $viewModel.searchText)
                        .font(.subheadline)
                        .foregroundStyle(Color.surgText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.surgSurface, in: RoundedRectangle(cornerRadius: 10))

                patientCountBadge
            }
        }
    }

    @ViewBuilder
    private var serviceNameRow: some View {
        if isEditingServiceName {
            @Bindable var state = appState
            TextField("Service Name", text: $state.serviceName)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.surgText)
                .focused($serviceNameFieldFocused)
                .onSubmit {
                    isEditingServiceName = false
                }
                .onAppear {
                    serviceNameFieldFocused = true
                }
        } else {
            Text(appState.serviceName)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.surgText)
                .onTapGesture {
                    isEditingServiceName = true
                }
        }
    }

    private var patientCountBadge: some View {
        let filtered = viewModel.filteredPatients(patients)
        return Text("\(filtered.count)")
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.surgAccent)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.surgAccent.opacity(0.15), in: Capsule())
    }

    // MARK: - Patient List

    private var patientList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                let sorted = viewModel.filteredPatients(patients)
                ForEach(sorted) { patient in
                    PatientCardView(patient: patient) {
                        viewModel.editingPatient = patient
                    } onDelete: {
                        viewModel.patientToDelete = patient
                        viewModel.showingDeleteConfirmation = true
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack(spacing: 0) {
            Button {
                viewModel.showingScanner = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "camera.viewfinder")
                        .font(.title2)
                    Text("Scan")
                        .font(.caption2.weight(.medium))
                }
                .foregroundStyle(Color.surgTextSecondary)
                .frame(maxWidth: .infinity)
            }

            Button {
                viewModel.showingAddForm = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.surgAccent)
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.surgAccent.opacity(0.4), radius: 12, y: 4)

                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)

            Button {
                viewModel.showingHandoff = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "qrcode")
                        .font(.title2)
                    Text("Handoff")
                        .font(.caption2.weight(.medium))
                }
                .foregroundStyle(patients.isEmpty ? Color.surgTextSecondary.opacity(0.4) : Color.surgTextSecondary)
                .frame(maxWidth: .infinity)
            }
            .disabled(patients.isEmpty)
        }
        .padding(.vertical, 12)
        .padding(.bottom, 4)
        .background {
            Color.surgSurface
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
        }
    }
}
