import Foundation
import SwiftData

/// A discrete task (to-do item) associated with a patient during a shift handoff.
@Model
final class PatientTask {
    @Attribute(.unique) var id: UUID
    var text: String
    var isDone: Bool
    var sortOrder: Int
    var patient: Patient?

    init(text: String, isDone: Bool = false, sortOrder: Int = 0) {
        self.id = UUID()
        self.text = text
        self.isDone = isDone
        self.sortOrder = sortOrder
    }
}
