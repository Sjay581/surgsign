import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

// MARK: - Secure Transfer Crypto

/// Wraps `AES.GCM` with the device-local transfer key stored in the
/// Keychain to seal and open handoff payloads before they are sent over
/// QR or Multipeer Connectivity.
///
/// The returned ciphertext is `AES.GCM.SealedBox.combined` — nonce ||
/// ciphertext || tag — so it can be passed through any byte-oriented
/// transport without additional framing.
///
/// This helper is intentionally orthogonal to `CompressionService`:
/// callers first compress, then seal, so the two steps can evolve
/// independently (e.g. a different compression format will not change the
/// envelope on the wire).
enum SecureTransferCrypto {

    // MARK: - Errors

    enum CryptoError: Error {
        /// The ciphertext could not be parsed as an `AES.GCM.SealedBox`.
        case invalidCiphertext
        /// Crypto support is unavailable on this platform.
        case unsupported
    }

    // MARK: - Seal / Open

    /// Encrypt `plaintext` using the device-local transfer key.
    /// - Returns: Combined AES-GCM ciphertext (nonce + ciphertext + tag).
    static func seal(_ plaintext: Data) throws -> Data {
        #if canImport(CryptoKit)
        let key = try KeychainService.transferKey()
        let box = try AES.GCM.seal(plaintext, using: key)
        guard let combined = box.combined else {
            // AES.GCM.seal with a default nonce always produces combined
            // output; hitting this branch implies a framework regression.
            throw CryptoError.invalidCiphertext
        }
        return combined
        #else
        throw CryptoError.unsupported
        #endif
    }

    /// Decrypt a combined AES-GCM ciphertext produced by `seal(_:)`.
    static func open(_ ciphertext: Data) throws -> Data {
        #if canImport(CryptoKit)
        let key = try KeychainService.transferKey()
        let box: AES.GCM.SealedBox
        do {
            box = try AES.GCM.SealedBox(combined: ciphertext)
        } catch {
            throw CryptoError.invalidCiphertext
        }
        return try AES.GCM.open(box, using: key)
        #else
        throw CryptoError.unsupported
        #endif
    }
}