import Foundation

extension DateFormatter {

    /// Full display format: "Apr 15, 2026"
    static let displayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// ISO 8601 date-only format: "2026-04-15"
    static let isoDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Compact short date format: "4/15"
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

extension Date {

    /// Formatted as "Apr 15, 2026".
    var displayString: String {
        DateFormatter.displayDate.string(from: self)
    }

    /// Formatted as "2026-04-15".
    var isoString: String {
        DateFormatter.isoDate.string(from: self)
    }
}