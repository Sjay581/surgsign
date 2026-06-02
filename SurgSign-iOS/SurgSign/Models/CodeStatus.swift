import SwiftUI

/// Patient code status for resuscitation directives.
enum CodeStatus: String, Codable, CaseIterable {
    case fullCode = "Full Code"
    case dnr = "DNR"
    case dni = "DNI"
    case dnrDni = "DNR/DNI"
    case comfortMeasures = "Comfort Measures"

    // MARK: - Display

    /// Theme color indicating the severity / nature of the code status.
    var color: Color {
        switch self {
        case .fullCode:         return .surgGreen
        case .dnr:              return .surgRed
        case .dni:              return .surgAM
        case .dnrDni:           return .surgRed
        case .comfortMeasures:  return .gray
        }
    }

    /// Abbreviated label for compact UI display.
    var shortLabel: String {
        switch self {
        case .fullCode:         return "Full"
        case .dnr:              return "DNR"
        case .dni:              return "DNI"
        case .dnrDni:           return "DNR/DNI"
        case .comfortMeasures:  return "CMO"
        }
    }
}