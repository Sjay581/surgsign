import Foundation
import SwiftData
import SwiftUI

/// Core data model representing a surgical patient on the service list.
///
/// Enums (`Priority`, `CodeStatus`) are stored as raw `String` values to ensure
/// reliable SwiftData persistence, with computed property wrappers for type-safe access.
@Model
final class Patient {
    @Attribute(.unique) var id: UUID
    var name: String
    var mrn: String
    var room: String
    var surgeon: String
    var diagnosis: String
    var procedure: String
    var surgeryDate: Date?
    var codeStatusRaw: String
    var allergies: String
    var priorityRaw: String
    var notes: String
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \PatientTask.patient)
    var tasks: [PatientTask]

    // MARK: - Computed Properties

    /// Type-safe accessor for code status.
    var codeStatus: CodeStatus {
        get { CodeStatus(rawValue: codeStatusRaw) ?? .fullCode }
        set { codeStatusRaw = newValue.rawValue }
    }

    /// Type-safe accessor for priority level.
    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .stable }
        set { priorityRaw = newValue.rawValue }
    }

    /// Post-operative day count calculated from `surgeryDate` to today.
    /// Returns `nil` if no surgery date is set.
    var postOpDay: Int? {
        PODCalculator.calculate(from: surgeryDate)
    }

    /// Human-readable post-op day label (e.g., "POD 3", "Pre-Op", "POD 0").
    var podLabel: String? {
        PODCalculator.label(for: surgeryDate)
    }

    /// Number of incomplete tasks for this patient.
    var pendingTaskCount: Int {
        tasks.filter { !$0.isDone }.count
    }

    /// Number of completed tasks for this patient.
    var completedTaskCount: Int {
        tasks.filter { $0.isDone }.count
    }

    // MARK: - Initializer

    init(
        name: String,
        mrn: String,
        room: String = "",
        surgeon: String = "",
        diagnosis: String = "",
        procedure: String = "",
        surgeryDate: Date? = nil,
        codeStatus: CodeStatus = .fullCode,
        allergies: String = "",
        priority: Priority = .stable,
        notes: String = "",
        sortOrder: Int = 0,
        tasks: [PatientTask] = []
    ) {
        self.id = UUID()
        self.name = name
        self.mrn = mrn
        self.room = room
        self.surgeon = surgeon
        self.diagnosis = diagnosis
        self.procedure = procedure
        self.surgeryDate = surgeryDate
        self.codeStatusRaw = codeStatus.rawValue
        self.allergies = allergies
        self.priorityRaw = priority.rawValue
        self.notes = notes
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()
        self.tasks = tasks
    }
}
