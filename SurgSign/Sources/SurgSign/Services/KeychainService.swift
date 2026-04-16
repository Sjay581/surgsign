import Foundation
#if canImport(Security)
import Security
#endif
#if canImport(CryptoKit)
import CryptoKit
#endif

// MARK: - Keychain Service

/// Minimal wrapper around the Keychain Services API used to persist small,
/// highly-sensitive secrets such as the AES key that encrypts handoff
/// payloads before transfer.
///
/// All items are written with:
/// - `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — the item is only
///   readable while the device is unlocked and is never migrated to a new
///   device via backup/restore.
/// - `kSecAttrSynchronizable = false` (default) — items are not synced via
///   iCloud Keychain.  Required for PHI.
enum KeychainService {

    // MARK: - Constants

    /// Service identifier used for every keychain entry owned by SurgSign.
    static let service = "com.surgsign.keychain"

    /// Account name used to store the symmetric AES key for transfer
    /// payload encryption.
    static let transferKeyAccount = "transfer.aes"

    // MARK: - Errors

    enum KeychainError: Error {
        case unhandled(OSStatus)
        case unexpectedData
    }

    // MARK: - CRUD

    /// Write `data` under `account`.  Overwrites any existing value.
    static func set(_ data: Data, for account: String) throws {
        #if canImport(Security)
        // Delete any existing item so we can use a clean SecItemAdd below.
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        _ = SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status)
        }
        #else
        throw KeychainError.unhandled(-1)
        #endif
    }

    /// Fetch the data stored under `account`, or `nil` if not present.
    static func get(_ account: String) -> Data? {
        #if canImport(Security)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
        #else
        return nil
        #endif
    }

    /// Remove the entry stored under `account`.  Not-found is not an error.
    static func delete(_ account: String) throws {
        #if canImport(Security)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandled(status)
        }
        #endif
    }

    // MARK: - Transfer Key Convenience

    #if canImport(CryptoKit)
    /// Returns the persistent 256-bit symmetric key used to seal/open
    /// handoff payloads.  Generates and stores a new key on first call.
    ///
    /// - Throws: `KeychainError` on a keychain failure, or
    ///   `KeychainError.unexpectedData` if a corrupt entry is already
    ///   present.
    static func transferKey() throws -> SymmetricKey {
        if let existing = get(transferKeyAccount) {
            guard existing.count == 32 else {
                throw KeychainError.unexpectedData
            }
            return SymmetricKey(data: existing)
        }

        let newKey = SymmetricKey(size: .bits256)
        let raw = newKey.withUnsafeBytes { Data(Array($0)) }
        try set(raw, for: transferKeyAccount)
        return newKey
    }
    #endif
}
