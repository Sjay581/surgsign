import SwiftUI
import SwiftData
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
#endif

/// Settings screen presented as a sheet from the patient list toolbar.
///
/// Provides shift / service configuration, JSON export + import of the
/// patient roster, bulk delete, and meta information (version, disclaimer
/// reset). Uses a dark, form-style layout that mirrors the rest of the app.
struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var patients: [Patient]

    @State private var showingDeleteAllConfirmation = false
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    @State private var showingImporter = false
    @State private var importResult: String? = nil
    @State private var errorMessage: String? = nil

    var body: some View {
        @Bindable var state = appState

        NavigationStack {
            ZStack {
                Color.surgBackground
                    .ignoresSafeArea()

                Form {
                    Section {
                        HStack {
                            Text("Service Name")
                                .foregroundStyle(Color.surgText)
                            Spacer()
                            TextField("Service Name", text: $state.serviceName)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(Color.surgTextSecondary)
                                .autocorrectionDisabled()
                        }

                        Picker("Shift", selection: Binding(
                            get: { appState.isAMShift },
                            set: { appState.isAMShift = $0 }
                        )) {
                            Text("AM").tag(true)
                            Text("PM").tag(false)
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("General")
                            .foregroundStyle(Color.surgTextSecondary)
                    }
                    .listRowBackground(Color.surgSurface)

                    dataManagementSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.surgSurface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.surgAccent)
                }
            }
            .confirmationDialog(
                "Delete All Patients?",
                isPresented: $showingDeleteAllConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete \(patients.count) Patients", role: .destructive) {
                    deleteAllPatients()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently remove every patient from the list. This cannot be undone.")
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImportResult(result)
            }
            .sheet(isPresented: $showingShareSheet) {
                #if canImport(UIKit)
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
                #endif
            }
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Data Management

    @ViewBuilder
    private var dataManagementSection: some View {
        Section {
            Button {
                exportPatients()
            } label: {
                Label("Export Patient List (JSON)", systemImage: "square.and.arrow.up")
                    .foregroundStyle(patients.isEmpty ? Color.surgTextSecondary : Color.surgAccent)
            }
            .disabled(patients.isEmpty)

            Button {
                importResult = nil
                showingImporter = true
            } label: {
                Label("Import Patient List (JSON)", systemImage: "square.and.arrow.down")
                    .foregroundStyle(Color.surgAccent)
            }

            if let importResult {
                Text(importResult)
                    .font(.caption)
                    .foregroundStyle(Color.surgGreen)
            }

            Button(role: .destructive) {
                showingDeleteAllConfirmation = true
            } label: {
                Label("Delete All Patients", systemImage: "trash")
                    .foregroundStyle(patients.isEmpty ? Color.surgTextSecondary : Color.surgRed)
            }
            .disabled(patients.isEmpty)

            HStack {
                Text("\(patients.count) patients currently on the list")
                    .font(.caption)
                    .foregroundStyle(Color.surgTextSecondary)
                Spacer()
            }
        } header: {
            Text("Data Management")
                .foregroundStyle(Color.surgTextSecondary)
        }
        .listRowBackground(Color.surgSurface)
    }

    // MARK: - About

    @ViewBuilder
    private var aboutSection: some View {
        Section {
            infoRow(label: "App", value: "SurgSign")
            infoRow(label: "Version", value: "1.0")

            Text("Prototype software — not for clinical use. Do not enter real patient information.")
                .font(.caption)
                .foregroundStyle(Color.surgRed.opacity(0.9))

            Button {
                appState.hasAcceptedDisclaimer = false
                dismiss()
            } label: {
                Label("Show Disclaimer Again", systemImage: "exclamationmark.shield")
                    .foregroundStyle(Color.surgAccent)
            }
        } header: {
            Text("About")
                .foregroundStyle(Color.surgTextSecondary)
        }
        .listRowBackground(Color.surgSurface)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Color.surgText)
            Spacer()
            Text(value).foregroundStyle(Color.surgTextSecondary)
        }
    }

    // MARK: - Actions

    private func exportPatients() {
        do {
            let url = try ExportImportService.exportJSON(
                patients: patients,
                serviceName: appState.serviceName,
                shift: appState.shiftLabel
            )
            exportURL = url
            showingShareSheet = true
            #if canImport(UIKit)
            surgHaptic(.light)
            #endif
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let count = try ExportImportService.importJSON(from: url, into: modelContext)
                importResult = "Imported \(count) patient\(count == 1 ? "" : "s")."
                #if canImport(UIKit)
                surgHaptic(.medium)
                #endif
            } catch {
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func deleteAllPatients() {
        for patient in patients {
            modelContext.delete(patient)
        }
        do {
            try modelContext.save()
            #if canImport(UIKit)
            surgHaptic(.heavy)
            #endif
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Share Sheet Wrapper

#if canImport(UIKit)
/// Thin `UIViewControllerRepresentable` wrapper around `UIActivityViewController`
/// so the exported JSON file URL can be shared via the standard iOS share sheet.
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No-op: activity view controller is static once created.
    }
}
#endif