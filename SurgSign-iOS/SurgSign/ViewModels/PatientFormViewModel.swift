import Foundation
import SwiftData
import SwiftUI

/// View model for the patient add / edit form.
///
/// Manages local form state, task list editing, and persisting changes
/// to the SwiftData model context.
@Observable
final class PatientFormViewModel {

    // MARK: - Form Fields

    var name: String = ""
    var mrn: String = ""
    var room: String = ""
    var surgeon: String = ""
    var diagnosis: String = ""
    var procedure: String = ""
    var surgeryDate: Date? = nil
    var hasSurgeryDate: Bool = false
    var codeStatus: CodeStatus = .fullCode
    var allergies: String = ""
    var priority: Priority = .medium
    var notes: String = ""
    var tasks: [TaskItem] = []
    var newTaskText: String = ""

    // MARK: - Editing State

    /// `true` when editing an existing patient rather than creating a new one.
    let isEditing: Bool

    /// The persisted UUID of the patient being edited, if any.
    private var patientID: UUID?

    // MARK: - Nested Types

    /// A local, non-persisted representation of a task used during form editing.
    struct TaskItem: Identifiable {
        let id: UUID
        var text: String
        var isDone: Bool

        init(id: UUID = UUID(), text: String, isDone: Bool = false) {
            self.id = id
            self.text = text
            self.isDone = isDone
        }
    }

    // MARK: - Initializers

    /// Initializer for creating a new patient.
    init() {
        self.isEditing = false
        self.patientID = nil
    }

    /// Initializer for editing an existing patient. Populates every form field
    /// from the model object.
    init(patient: Patient) {
        self.isEditing = true
        self.patientID = patient.id
        self.name = patient.name
        self.mrn = patient.mrn
        self.room = patient.room
        self.surgeon = patient.surgeon
        self.diagnosis = patient.diagnosis
        self.procedure = patient.procedure
        self.surgeryDate = patient.surgeryDate
        self.hasSurgeryDate = patient.surgeryDate != nil
        self.codeStatus = patient.codeStatus
        self.allergies = patient.allergies
        self.priority = patient.priority
        self.notes = patient.notes
        self.tasks = patient.tasks
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { TaskItem(id: $0.id, text: $0.text, isDone: $0.isDone) }
    }

    // MARK: - Validation

    /// The form is valid when the patient name is non-empty after trimming whitespace.
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Task Editing

    /// Adds the current `newTaskText` as a new task item, then clears the text field.
    func addTask() {
        let trimmed = newTaskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks.append(TaskItem(text: trimmed))
        newTaskText = ""
    }

    /// Removes the specified task from the local list.
    func removeTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
    }

    /// Toggles the done state of the specified task.
    func toggleTask(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isDone.toggle()
    }

    // MARK: - Persistence

    /// Saves the form data to the given SwiftData context.
    ///
    /// When editing, the existing `Patient` is fetched by ID and updated in place.
    /// When creating, a new `Patient` is inserted into the context.
    func save(context: ModelContext) {
        if isEditing, let patientID {
            updateExistingPatient(id: patientID, context: context)
        } else {
            createNewPatient(context: context)
        }

        try? context.save()
    }

    /// Deletes the patient currently being edited from the context.
    /// No-op when creating a new patient.
    func delete(context: ModelContext) {
        guard isEditing, let patientID else { return }
        let targetID = patientID
        var descriptor = FetchDescriptor<Patient>(
            predicate: #Predicate { $0.id == targetID }
        )
        descriptor.fetchLimit = 1

        guard let patient = try? context.fetch(descriptor).first else { return }
        context.delete(patient)
        try? context.save()
    }

    // MARK: - Private Helpers

    private func createNewPatient(context: ModelContext) {
        let effectiveDate: Date? = hasSurgeryDate ? surgeryDate : nil

        let patientTasks = tasks.enumerated().map { index, item in
            PatientTask(text: item.text, isDone: item.isDone, sortOrder: index)
        }

        let patient = Patient(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            mrn: mrn.trimmingCharacters(in: .whitespacesAndNewlines),
            room: room.trimmingCharacters(in: .whitespacesAndNewlines),
            surgeon: surgeon.trimmingCharacters(in: .whitespacesAndNewlines),
            diagnosis: diagnosis.trimmingCharacters(in: .whitespacesAndNewlines),
            procedure: procedure.trimmingCharacters(in: .whitespacesAndNewlines),
            surgeryDate: effectiveDate,
            codeStatus: codeStatus,
            allergies: allergies.trimmingCharacters(in: .whitespacesAndNewlines),
            priority: priority,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            sortOrder: 0,
            tasks: patientTasks
        )

        context.insert(patient)
    }

    private func updateExistingPatient(id: UUID, context: ModelContext) {
        let targetID = id
        var descriptor = FetchDescriptor<Patient>(
            predicate: #Predicate { $0.id == targetID }
        )
        descriptor.fetchLimit = 1

        guard let patient = try? context.fetch(descriptor).first else { return }

        patient.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.mrn = mrn.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.room = room.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.surgeon = surgeon.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.diagnosis = diagnosis.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.procedure = procedure.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.surgeryDate = hasSurgeryDate ? surgeryDate : nil
        patient.codeStatus = codeStatus
        patient.allergies = allergies.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.priority = priority
        patient.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.updatedAt = Date()

        // Reconcile tasks: remove old ones that no longer exist, update existing,
        // and add new ones.
        let formTaskIDs = Set(tasks.map(\.id))

        // Delete tasks that were removed from the form.
        for existingTask in patient.tasks where !formTaskIDs.contains(existingTask.id) {
            context.delete(existingTask)
        }

        // Build a lookup of existing persisted tasks by ID.
        let existingTasksByID = Dictionary(
            uniqueKeysWithValues: patient.tasks.map { ($0.id, $0) }
        )

        var updatedTasks: [PatientTask] = []
        for (index, item) in tasks.enumerated() {
            if let existing = existingTasksByID[item.id] {
                // Update in place.
                existing.text = item.text
                existing.isDone = item.isDone
                existing.sortOrder = index
                updatedTasks.append(existing)
            } else {
                // Create a new task.
                let newTask = PatientTask(text: item.text, isDone: item.isDone, sortOrder: index)
                updatedTasks.append(newTask)
            }
        }

        patient.tasks = updatedTasks
    }
}