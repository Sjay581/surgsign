import SwiftUI

/// Clinical priority level for a patient, ordered from most to least urgent.
enum Priority: String, Codable, CaseIterable, Comparable {
    case high
    case medium
    case low
    case stable

    // MARK: - Sort Order

    /// Numeric sort order where lower values represent higher priority.
    var sortOrder: Int {
        switch self {
        case .high:   return 0
        case .medium: return 1
        case .low:    return 2
        case .stable: return 3
        }
    }

    // MARK: - Display

    /// Theme color associated with this priority level.
    var color: Color {
        switch self {
        case .high:   return .surgRed
        case .medium: return .surgAM
        case .low:    return .surgGreen
        case .stable: return .gray
        }
    }

    /// Human-readable label (capitalized).
    var label: String {
        rawValue.capitalized
    }

    /// SF Symbol name for visual indicators.
    var icon: String {
        switch self {
        case .high:   return "exclamationmark.triangle.fill"
        case .medium: return "arrow.up.circle.fill"
        case .low:    return "arrow.down.circle.fill"
        case .stable: return "checkmark.circle.fill"
        }
    }

    // MARK: - Comparable

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
