import SwiftUI

/// Observable application-level state persisted across launches via UserDefaults.
@Observable
final class AppState {

    // MARK: - UserDefaults Keys

    private enum DefaultsKey {
        static let isAMShift = "surgsign_isAMShift"
        static let serviceName = "surgsign_serviceName"
        static let hasAcceptedDisclaimer = "surgsign_hasAcceptedDisclaimer"
    }

    // MARK: - Stored Properties

    /// Whether the current shift is AM (day) or PM (night).
    var isAMShift: Bool {
        didSet { UserDefaults.standard.set(isAMShift, forKey: DefaultsKey.isAMShift) }
    }

    /// The name of the surgical service (e.g., "General Surgery", "Trauma").
    var serviceName: String {
        didSet { UserDefaults.standard.set(serviceName, forKey: DefaultsKey.serviceName) }
    }

    /// Whether the user has accepted the medical disclaimer.
    var hasAcceptedDisclaimer: Bool {
        didSet { UserDefaults.standard.set(hasAcceptedDisclaimer, forKey: DefaultsKey.hasAcceptedDisclaimer) }
    }

    // MARK: - Computed Properties

    /// Short label for the current shift type.
    var shiftLabel: String {
        isAMShift ? "AM" : "PM"
    }

    /// Theme color representing the current shift type.
    var shiftColor: Color {
        isAMShift ? .surgAM : .surgPM
    }

    // MARK: - Initializer

    init() {
        let defaults = UserDefaults.standard

        // Default to AM shift if no value has been stored yet.
        if defaults.object(forKey: DefaultsKey.isAMShift) == nil {
            self.isAMShift = true
        } else {
            self.isAMShift = defaults.bool(forKey: DefaultsKey.isAMShift)
        }

        self.serviceName = defaults.string(forKey: DefaultsKey.serviceName) ?? "General Surgery"
        self.hasAcceptedDisclaimer = defaults.bool(forKey: DefaultsKey.hasAcceptedDisclaimer)
    }

    // MARK: - Actions

    /// Toggles between AM and PM shift.
    func toggleShift() {
        isAMShift.toggle()
    }
}