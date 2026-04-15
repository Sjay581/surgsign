import SwiftUI
import SwiftData

/// Full patient add/edit form presented as a modal sheet.
///
/// Organized into four sections: identity, clinical information, tasks, and notes.
/// Supports both creating new patients and editing existing ones.
struct PatientFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: PatientFormViewModel
    @State private var showDeleteConfirmation = false

    // MARK: - Initializers

    /// Create a form for adding a new patient.
    init() {
        _viewModel = State(initialValue: PatientFormViewModel())
    }

    /// Create a form for editing an existing patient.
    init(patient: Patient) {
        _viewModel = State(initialValue: PatientFormViewModel(patient: patient))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surgBackground
                    .ignoresSafeArea()

                formContent
            }
            .navigationTitle(viewModel.isEditing ? "Edit Patient" : "New Patient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.surgSurface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.surgTextSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save(context: modelContext)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.isValid ? Color.surgAccent : Color.surgTextSecondary.opacity(0.4))
                    .disabled(!viewModel.isValid)
                }
            }
            .alert("Delete Patient", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    viewModel.delete(context: modelContext)
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently remove this patient from your list. This action cannot be undone.")
            }
        }
    }

    // MARK: - Form Content

    private var formContent: some View {
        Form {
            patientIdentitySection
            clinicalInformationSection
            TaskListSectionView(viewModel: viewModel)
            notesSection

            if viewModel.isEditing {
                deleteSection
            }
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Section 1: Patient Identity

    private var patientIdentitySection: some View {
        Section {
            formTextField("Name", text: $viewModel.name, placeholder: "Last, First MI", required: true)
            formTextField("MRN", text: $viewModel.mrn, placeholder: "Medical Record Number")
                .textContentType(.none)
                .keyboardType(.numberPad)
            formTextField("Room/Bed", text: $viewModel.room, placeholder: "e.g., 4B-12")
            formTextField("Attending", text: $viewModel.surgeon, placeholder: "Attending Surgeon")
        } header: {
            Text("Patient Identity")
        }
        .listRowBackground(Color.surgSurface)
    }

    // MARK: - Section 2: Clinical Information

    private var clinicalInformationSection: some View {
        Section {
            formTextField("Diagnosis", text: $viewModel.diagnosis, placeholder: "Primary diagnosis")
            formTextField("Procedure", text: $viewModel.procedure, placeholder: "Surgical procedure")
            surgeryDateRow
            codeStatusRow
            priorityRow
            formTextField("Allergies", text: $viewModel.allergies, placeholder: "NKDA if none")
        } header: {
            Text("Clinical Information")
        }
        .listRowBackground(Color.surgSurface)
    }

    // MARK: - Surgery Date

    private var surgeryDateRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $viewModel.hasSurgeryDate) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.surgAccent)
                        .font(.subheadline)
                    Text("Surgery Date")
                        .font(.subheadline)
                        .foregroundStyle(Color.surgText)
                }
            }
            .tint(Color.surgAccent)

            if viewModel.hasSurgeryDate {
                DatePicker(
                    "Date",
                    selection: Binding(
                        get: { viewModel.surgeryDate ?? Date() },
                        set: { viewModel.surgeryDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .tint(Color.surgAccent)

                if let podLabel = PODCalculator.label(for: viewModel.surgeryDate) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text(podLabel)
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(PODCalculator.color(for: viewModel.surgeryDate))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        PODCalculator.color(for: viewModel.surgeryDate).opacity(0.12),
                        in: Capsule()
                    )
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Code Status Picker

    private var codeStatusRow: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "heart.text.square")
                    .foregroundStyle(viewModel.codeStatus.color)
                    .font(.subheadline)
                Text("Code Status")
                    .font(.subheadline)
                    .foregroundStyle(Color.surgText)
            }

            Spacer()

            Picker("", selection: $viewModel.codeStatus) {
                ForEach(CodeStatus.allCases, id: \.self) { status in
                    Text(status.rawValue).tag(status)
                }
            }
            .tint(viewModel.codeStatus.color)
        }
    }

    // MARK: - Priority Picker

    private var priorityRow: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: viewModel.priority.icon)
                    .foregroundStyle(viewModel.priority.color)
                    .font(.subheadline)
                Text("Priority")
                    .font(.subheadline)
                    .foregroundStyle(Color.surgText)
            }

            Spacer()

            Picker("", selection: $viewModel.priority) {
                ForEach(Priority.allCases, id: \.self) { priority in
                    Label(priority.label, systemImage: priority.icon)
                        .tag(priority)
                }
            }
            .tint(viewModel.priority.color)
        }
    }

    // MARK: - Section 4: Notes

    private var notesSection: some View {
        Section {
            TextEditor(text: $viewModel.notes)
                .font(.subheadline)
                .foregroundStyle(Color.surgText)
                .frame(minHeight: 120)
                .scrollContentBackground(.hidden)
                .overlay(alignment: .topLeading) {
                    if viewModel.notes.isEmpty {
                        Text("Contingency plan, overnight events, key concerns...")
                            .font(.subheadline)
                            .foregroundStyle(Color.surgTextSecondary.opacity(0.5))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                }
        } header: {
            Text("Notes & Contingency Plan")
        }
        .listRowBackground(Color.surgSurface)
    }

    // MARK: - Delete Section

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "trash")
                    Text("Delete Patient")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .foregroundStyle(Color.surgRed)
            }
        }
        .listRowBackground(Color.surgRed.opacity(0.08))
    }

    // MARK: - Helpers

    /// A styled form text field with a label and placeholder.
    private func formTextField(
        _ label: String,
        text: Binding<String>,
        placeholder: String,
        required: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.surgTextSecondary)
                if required {
                    Text("*")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.surgRed)
                }
            }
            TextField(placeholder, text: text)
                .font(.subheadline)
                .foregroundStyle(Color.surgText)
                .autocorrectionDisabled()
        }
        .padding(.vertical, 2)
    }
}
