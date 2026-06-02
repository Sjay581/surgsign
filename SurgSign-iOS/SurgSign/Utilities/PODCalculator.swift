import SwiftUI

/// Visual classification of a post-operative day range.
enum PODStyle {
    case preOp
    case dayOfSurgery
    case early
    case mid
    case late
}

/// Utility for calculating post-operative day (POD) values and their display attributes.
struct PODCalculator {

    /// Calculates the number of days since surgery.
    ///
    /// - Returns: A negative value for pre-op (days until surgery), `0` for day-of,
    ///   a positive value for post-op days, or `nil` if no surgery date is provided.
    static func calculate(from surgeryDate: Date?) -> Int? {
        guard let surgeryDate else { return nil }
        let calendar = Calendar.current
        let startOfSurgery = calendar.startOfDay(for: surgeryDate)
        let startOfToday = calendar.startOfDay(for: Date())
        let components = calendar.dateComponents([.day], from: startOfSurgery, to: startOfToday)
        return components.day
    }

    /// Returns a human-readable label for the post-operative day.
    ///
    /// Examples: `"Pre-Op"`, `"POD 0"`, `"POD 3"`.
    static func label(for surgeryDate: Date?) -> String? {
        guard let pod = calculate(from: surgeryDate) else { return nil }

        if pod < 0 {
            return "Pre-Op"
        } else {
            return "POD \(pod)"
        }
    }

    /// Returns the visual style classification for a given POD value.
    static func style(for pod: Int?) -> PODStyle {
        guard let pod else { return .preOp }

        switch pod {
        case ..<0:   return .preOp
        case 0:      return .dayOfSurgery
        case 1...2:  return .early
        case 3...7:  return .mid
        default:     return .late
        }
    }

    /// Returns the theme color appropriate for the patient's post-operative stage.
    static func color(for surgeryDate: Date?) -> Color {
        let pod = calculate(from: surgeryDate)
        let podStyle = style(for: pod)

        switch podStyle {
        case .preOp:         return .surgAccent
        case .dayOfSurgery:  return .surgAccent
        case .early:         return .surgGreen
        case .mid:           return .surgAM
        case .late:          return .surgRed
        }
    }
}