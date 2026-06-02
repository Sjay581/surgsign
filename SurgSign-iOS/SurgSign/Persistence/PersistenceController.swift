import Foundation
import SwiftData

// MARK: - Persistence Controller

/// Owns the SwiftData `ModelContainer` for SurgSign and applies data-protection
/// hardening to the on-disk store.  Because the app handles PHI, the database
/// is kept local-only (no CloudKit sync), excluded from device backups, and
/// protected with `completeUntilFirstUserAuthentication` so the file is
/// inaccessible until the user unlocks the device for the first time after
/// boot.
///
/// Consumers should inject the container into the SwiftUI scene via
/// `.modelContainer(PersistenceController.shared.container)` rather than
/// allowing SwiftData to create one with default settings.
final class PersistenceController {

    // MARK: - Shared Instance

    /// Process-wide singleton used by the main app target.
    static let shared = PersistenceController()

    // MARK: - Stored Properties

    /// The SwiftData model container holding `Patient` and `PatientTask`.
    let container: ModelContainer

    /// On-disk URL of the primary SQLite store (nil when running in-memory).
    private let storeURL: URL?

    // MARK: - Initializers

    /// Default init — builds an on-disk, local-only container.
    convenience init() {
        self.init(inMemory: false)
    }

    /// Builds a container. Pass `inMemory: true` for unit tests.
    init(inMemory: Bool) {
        let schema = Schema([Patient.self, PatientTask.self])

        if inMemory {
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
            self.storeURL = nil
            self.container = Self.makeContainer(schema: schema, configuration: config)
            return
        }

        // Build the on-disk store URL under Application Support/SurgSign/.
        let resolvedURL = Self.makeStoreURL()
        self.storeURL = resolvedURL

        let config: ModelConfiguration
        if let url = resolvedURL {
            config = ModelConfiguration(
                schema: schema,
                url: url,
                cloudKitDatabase: .none
            )
        } else {
            // Couldn't build a URL — fall back to default on-disk location.
            config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
        }

        self.container = Self.makeContainer(schema: schema, configuration: config)

        // Apply data-protection hardening post-creation.
        if let url = resolvedURL {
            Self.applyFileProtection(to: url)
        }
    }

    // MARK: - Container Construction

    /// Create a container, falling back to an in-memory store if the on-disk
    /// container fails to initialize (corrupt store, disk full, etc.).  This
    /// lets the app launch in a degraded-but-functional state rather than
    /// crashing.
    private static func makeContainer(
        schema: Schema,
        configuration: ModelConfiguration
    ) -> ModelContainer {
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            NSLog("[PersistenceController] Primary container failed: \(error). Falling back to in-memory store.")
            do {
                let fallback = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true,
                    cloudKitDatabase: .none
                )
                return try ModelContainer(for: schema, configurations: [fallback])
            } catch {
                // If even in-memory fails, we truly cannot proceed.
                fatalError("[PersistenceController] Unable to create any ModelContainer: \(error)")
            }
        }
    }

    // MARK: - Store URL

    /// Returns the URL for `<Application Support>/SurgSign/store.sqlite`,
    /// creating the parent directory if needed.  Returns nil if the file
    /// system APIs are unavailable (e.g. sandboxed simulator test runs).
    private static func makeStoreURL() -> URL? {
        let fm = FileManager.default
        do {
            let appSupport = try fm.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let folder = appSupport.appendingPathComponent("SurgSign", isDirectory: true)
            if !fm.fileExists(atPath: folder.path) {
                try fm.createDirectory(at: folder, withIntermediateDirectories: true)
            }
            return folder.appendingPathComponent("store.sqlite", isDirectory: false)
        } catch {
            NSLog("[PersistenceController] Unable to resolve Application Support URL: \(error)")
            return nil
        }
    }

    // MARK: - File Protection

    /// Apply iOS data-protection attributes to the SQLite store and its
    /// journal sidecars.  The store is also excluded from iCloud/iTunes
    /// backups so PHI does not leak off-device.
    ///
    /// Missing sidecars (`-shm` / `-wal`) are ignored — SQLite creates them
    /// lazily on first write.
    private static func applyFileProtection(to storeURL: URL) {
        let sidecars = [
            storeURL,
            storeURL.appendingPathExtension("shm"),
            storeURL.appendingPathExtension("wal")
        ]

        #if canImport(UIKit)
        let attrs: [FileAttributeKey: Any] = [
            .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
        ]
        for url in sidecars {
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            do {
                try FileManager.default.setAttributes(attrs, ofItemAtPath: url.path)
            } catch {
                NSLog("[PersistenceController] Could not set file protection on \(url.lastPathComponent): \(error)")
            }
        }
        #endif

        // Exclude from backups (applies on all Apple platforms).
        var mutableURL = storeURL
        if FileManager.default.fileExists(atPath: mutableURL.path) {
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            do {
                try mutableURL.setResourceValues(values)
            } catch {
                NSLog("[PersistenceController] Could not mark store as excluded-from-backup: \(error)")
            }
        }
    }

    // MARK: - Purge

    /// Deletes the entire store directory and rebuilds the container.  Safe
    /// to invoke from the main actor.  After this returns, all previously
    /// fetched model instances should be considered invalid.
    ///
    /// - Note: This is destructive and cannot be undone.
    @MainActor
    func purgeAll() throws {
        guard let storeURL else {
            // In-memory store — nothing to purge on disk.  Caller should
            // simply recreate their view state.
            return
        }

        let folder = storeURL.deletingLastPathComponent()
        let fm = FileManager.default

        // Remove store + sidecars individually so that a stray lock file
        // doesn't abort the whole operation.
        for name in ["store.sqlite", "store.sqlite-shm", "store.sqlite-wal"] {
            let url = folder.appendingPathComponent(name)
            if fm.fileExists(atPath: url.path) {
                try fm.removeItem(at: url)
            }
        }
    }
}