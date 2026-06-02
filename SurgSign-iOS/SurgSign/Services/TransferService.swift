import Foundation
import UIKit

// MARK: - Transfer Service

/// Unified interface for encoding and decoding patient handoff data across
/// QR code and peer-to-peer transfer channels.
///
/// - QR transfers use the `CompressionService` to produce an SS2 or SS3
///   encoded string that fits within QR code capacity limits.
/// - Peer-to-peer transfers send raw JSON `Data` over Multipeer Connectivity,
///   avoiding the QR size constraint entirely.
struct TransferService {

    // MARK: - Encoding

    /// Encode patients into a compressed string suitable for a QR code.
    ///
    /// Uses the SS2 (LZ-String) format for cross-platform PWA compatibility.
    /// If the payload exceeds QR capacity at that format, falls back to SS3
    /// (zlib) which typically produces smaller output.
    ///
    /// - Parameters:
    ///   - patients: Patient data to transfer.
    ///   - serviceName: Surgical service name (e.g. "General Surgery").
    ///   - shift: Shift identifier ("AM" or "PM").
    /// - Returns: A compressed, QR-ready string.
    static func encodeForQR(
        patients: [PatientTransferData],
        serviceName: String,
        shift: String
    ) throws -> String {
        let payload = TransferPayload.build(
            patients: patients,
            serviceName: serviceName,
            shift: shift
        )

        // Try SS2 first for PWA compatibility.
        let ss2 = try CompressionService.encode(payload)
        let (_, overLimit) = QRCodeService.estimateQRCapacity(ss2)

        if !overLimit {
            return ss2
        }

        // Fall back to SS3 (zlib) which is usually smaller.
        let ss3 = try CompressionService.encodeNative(payload)
        let (_, stillOver) = QRCodeService.estimateQRCapacity(ss3)

        if stillOver {
            throw TransferError.payloadTooLarge
        }

        return ss3
    }

    /// Encode patients into raw JSON `Data` for Multipeer Connectivity transfer.
    ///
    /// No compression is applied — the peer-to-peer channel has no size limit.
    ///
    /// - Parameters:
    ///   - patients: Patient data to transfer.
    ///   - serviceName: Surgical service name (e.g. "General Surgery").
    ///   - shift: Shift identifier ("AM" or "PM").
    /// - Returns: JSON-encoded `Data`.
    static func encodeForPeer(
        patients: [PatientTransferData],
        serviceName: String,
        shift: String
    ) throws -> Data {
        let payload = TransferPayload.build(
            patients: patients,
            serviceName: serviceName,
            shift: shift
        )
        return try payload.jsonData()
    }

    // MARK: - Decoding

    /// Decode a QR code string (SS2 or SS3 format) into a `TransferPayload`.
    static func decodeQR(_ qrString: String) throws -> TransferPayload {
        try CompressionService.decode(qrString)
    }

    /// Decode raw JSON `Data` received over Multipeer Connectivity.
    static func decodePeer(_ data: Data) throws -> TransferPayload {
        try TransferPayload.from(jsonData: data)
    }

    // MARK: - Convenience

    /// Convenience to generate a QR code `UIImage` for a set of patients.
    ///
    /// - Parameters:
    ///   - patients: Patient data to encode.
    ///   - serviceName: Surgical service name.
    ///   - shift: Shift identifier.
    ///   - size: Desired image dimension in points.
    /// - Returns: A `UIImage` containing the QR code, or `nil` on failure.
    static func generateQRImage(
        patients: [PatientTransferData],
        serviceName: String,
        shift: String,
        size: CGFloat = 300
    ) throws -> UIImage? {
        let encoded = try encodeForQR(
            patients: patients,
            serviceName: serviceName,
            shift: shift
        )
        let correctionLevel = QRCodeService.suggestedCorrectionLevel(for: encoded)
        return QRCodeService.generateQRCode(
            from: encoded,
            size: size,
            correctionLevel: correctionLevel
        )
    }
}

// MARK: - Errors

enum TransferError: LocalizedError {
    case payloadTooLarge

    var errorDescription: String? {
        switch self {
        case .payloadTooLarge:
            return "The patient list is too large to fit in a single QR code. "
                + "Try reducing the number of patients or using peer-to-peer transfer."
        }
    }
}