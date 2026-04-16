import Foundation
#if canImport(LocalAuthentication)
import LocalAuthentication
#endif

// MARK: - Biometric Gate

/// Gates access to the patient list behind a local biometric / passcode
/// authentication challenge.  Uses `.deviceOwnerAuthentication`, which
/// prompts for Face ID or Touch ID first and falls back to the device
/// passcode if biometrics are unavailable or fail repeatedly.
///
/// The gate is opt-in (default `isEnabled = false`) because some
/// clinicians share iPads and need passcode-free access during rounds.
@MainActor
@Observable
final class BiometricGate {

    // MARK: - Constants

    /// Prompt shown by the system auth sheet.  Kept short per HIG.
    static let reason = "Unlock SurgSign to view patient data."

    private enum Keys {
        static let isEnabled = "BiometricGate.isEnabled"
    }

    // MARK: - Observable State

    /// True when the UI should hide PHI behind a lock screen.  Starts
    /// locked if the gate is enabled.
    var isLocked: Bool

    /// Master switch.  Persisted in UserDefaults.
    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled)
            // If the user just disabled the gate, drop the lock so they
            // are not left staring at a blocked UI.
            if !isEnabled { isLocked = false }
        }
    }

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        let enabled = defaults.bool(forKey: Keys.isEnabled)
        self.isEnabled = enabled
        self.isLocked = enabled
    }

    // MARK: - Public API

    /// Prompt the user for biometric / passcode auth.  Returns `true` on
    /// success and transitions `isLocked` to `false`.  A no-op (returns
    /// `true`) when the gate is disabled so callers can treat the gate
    /// as transparent when not in use.
    func unlock() async -> Bool {
        guard isEnabled else {
            isLocked = false
            return true
        }

        #if canImport(LocalAuthentication)
        let context = LAContext()
        var evalError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &evalError) else {
            // Policy cannot be evaluated (e.g. no passcode set).  Refuse
            // rather than silently unlocking — an empty passcode means
            // the device isn't really locked anyway.
            NSLog("[BiometricGate] canEvaluatePolicy failed: \(String(describing: evalError))")
            return false
        }

        do {
            let ok = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: Self.reason
            )
            if ok { isLocked = false }
            return ok
        } catch {
            NSLog("[BiometricGate] evaluatePolicy error: \(error)")
            return false
        }
        #else
        // On platforms without LocalAuthentication (Linux tests), treat
        // the gate as non-functional; callers can still exercise the
        // enable/disable logic.
        return false
        #endif
    }

    /// Re-engage the lock.  Called from a scene-phase observer when the
    /// app resigns active.
    func lock() {
        guard isEnabled else { return }
        isLocked = true
    }
}
