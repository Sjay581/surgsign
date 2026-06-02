import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

// MARK: - QR Code Service

/// Generates QR code images and checks payload capacity limits.
struct QRCodeService {

    /// Maximum byte capacity of a QR Version 40 code with Medium error
    /// correction in byte mode.
    static let qrMaxBytesMediumEC = 2_953

    // MARK: - Generation

    /// Generate a `UIImage` containing a QR code for the given string.
    ///
    /// - Parameters:
    ///   - string: The data to encode in the QR code.
    ///   - size: The desired point size (width & height) of the output image.
    ///   - correctionLevel: Core Image QR correction level — "L", "M", "Q", or "H".
    /// - Returns: A `UIImage` if generation succeeds, otherwise `nil`.
    static func generateQRCode(
        from string: String,
        size: CGFloat = 300,
        correctionLevel: String = "M"
    ) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        guard let data = string.data(using: .utf8) else { return nil }
        filter.message = data
        filter.correctionLevel = correctionLevel

        guard let ciImage = filter.outputImage else { return nil }

        // Scale to requested size using nearest-neighbor for crisp edges.
        let scaleX = size / ciImage.extent.size.width
        let scaleY = size / ciImage.extent.size.height
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    // MARK: - Capacity Estimation

    /// Estimate the byte size of a string and check whether it fits in a
    /// standard QR code.
    ///
    /// - Parameter string: The encoded payload string that would go into the QR.
    /// - Returns: A tuple with the byte count and a flag indicating overflow.
    static func estimateQRCapacity(_ string: String) -> (bytes: Int, isOverLimit: Bool) {
        let byteCount = string.utf8.count
        return (bytes: byteCount, isOverLimit: byteCount > qrMaxBytesMediumEC)
    }

    /// Suggest an error correction level based on payload size.
    ///
    /// Smaller payloads can afford higher EC; larger payloads may need Low EC
    /// to fit within QR Version 40 capacity.
    ///
    /// | Level | V40 Byte Capacity |
    /// |-------|-------------------|
    /// | L     | 4,296             |
    /// | M     | 2,953             |  (default target)
    /// | Q     | 2,078             |
    /// | H     | 1,276             |
    static func suggestedCorrectionLevel(for string: String) -> String {
        let bytes = string.utf8.count
        if bytes <= 1_276 {
            return "H"
        } else if bytes <= 2_078 {
            return "Q"
        } else if bytes <= 2_953 {
            return "M"
        } else if bytes <= 4_296 {
            return "L"
        } else {
            // Over limit even at lowest EC — caller should split or compress more.
            return "L"
        }
    }
}