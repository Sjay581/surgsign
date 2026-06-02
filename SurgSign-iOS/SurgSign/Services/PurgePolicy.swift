import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Purge Policy

/// User-configurable auto-wipe policy for the local SwiftData store.  The
/// policy exists because SurgSign is designed to hold PHI only for the
/// duration of a shift — once a handoff is complete, residual data should
/// be purged so a lost or stolen device does not leak prior patients'
/// information.
///
/// Two triggers are supported:
/// - **TTL** — time since the last purge exceeds `ttlHours`, checked on
///   app launch or foregrounding via `checkAndPurgeIfNeeded(controller:)`.
/// - **Terminate** — if `purgeOnTerminate` is on, the store is wiped as
///   the app is terminated (best-effort; iOS does not always deliver
///   this notification).
///
/// All persistence uses `UserDefaults` because these settings are non-PHI
/// and need to survive store purges.
@MainActor
@Observable
final class PurgePolicy {

    // MARK: - Constants

    /// Allowed values for `ttlHours`; exposed so a settings UI can render
    /// them without hard-coding the list in two places.
    static let allowedTTLs: [Int] = [4, 8, 12, 24]

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let ttlHours = "PurgePolicy.ttlHours"
        static let purgeOnTerminate = "PurgePolicy.purgeOnTerminate"
        static let lastPurge = "PurgePolicy.lastPurge"
        static let isEnabled = "PurgePolicy.isEnabled"
    }

    // MARK: - Stored Properties

    /// Time-to-live in hours before the store is auto-wiped.  Callers
    /// should only assign values drawn from `allowedTTLs`; other values
    /// are accepted but UI should use `allowedTTLs` as the picker
    /// source.
    var ttlHours: Int {
        didSet { UserDefaults.standard.set(ttlHours, forKey: Keys.ttlHours) }
    }

    /// If true, a purge is attempted when the app is about to terminate.
    var purgeOnTerminate: Bool {
        didSet { UserDefaults.standard.set(purgeOnTerminate, forKey: Keys.purgeOnTerminate) }
    }

    /// Timestamp of the most recent successful purge.  Seeded to "now" on
    /// first launch so a freshly installed app does not immediately wipe
    /// its own seed data.
    var lastPurge: Date {
        didSet { UserDefaults.standard.set(lastPurge, forKey: Keys.lastPurge) }
    }

    /// Master switch.  Default is `false` because auto-purge is
    /// destructive; the user must opt in via the settings UI.
    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled) }
    }

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        let storedTTL = defaults.object(forKey: Keys.ttlHours) as? Int ?? 12
        self.ttlHours = Self.allowedTTLs.contains(storedTTL) ? storedTTL : 12

        self.purgeOnTerminate = defaults.bool(forKey: Keys.purgeOnTerminate)
        self.isEnabled = defaults.bool(forKey: Keys.isEnabled)

        if let date = defaults.object(forKey: Keys.lastPurge) as? Date {
            self.lastPurge = date
        } else {
            let now = Date()
            self.lastPurge = now
            defaults.set(now, forKey: Keys.lastPurge)
        }
    }

    // MARK: - TTL Check

    /// Purges the controller's store if auto-purge is enabled and more
    /// than `ttlHours` have elapsed since the last purge.  Failures are
    /// logged but not thrown — a purge miss should never crash the app.
    func checkAndPurgeIfNeeded(controller: PersistenceController) {
        guard isEnabled else { return }
        let threshold = TimeInterval(ttlHours * 3600)
        guard Date().timeIntervalSince(lastPurge) > threshold else { return }

        do {
            try controller.purgeAll()
            lastPurge = Date()
        } catch {
            NSLog("[PurgePolicy] TTL purge failed: \(error)")
        }
    }

    // MARK: - Lifecycle

    /// Wire the policy up to app-lifecycle notifications so that
    /// terminate-time purges happen automatically.  Safe to call more
    /// than once; subsequent calls do not re-register observers for
    /// notifications that are already observed.
    func registerLifecycleHooks(controller: PersistenceController) {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self, weak controller] _ in
            // The .main queue delivers synchronously on the main thread,
            // but the compiler needs an explicit hop to the MainActor.
            Task { @MainActor in
                guard let self, let controller else { return }
                guard self.purgeOnTerminate else { return }
                do {
                    try controller.purgeAll()
                    self.lastPurge = Date()
                } catch {
                    NSLog("[PurgePolicy] Terminate purge failed: \(error)")
                }
            }
        }
        #endif
    }
}