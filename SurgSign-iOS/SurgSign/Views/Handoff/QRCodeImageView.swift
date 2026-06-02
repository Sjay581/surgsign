import SwiftUI

/// Displays a QR code `UIImage` with crisp pixel rendering and a white
/// background for optimal scanner readability.
struct QRCodeImageView: View {
    let image: UIImage?

    /// Desired display size (width and height) of the QR code container.
    var size: CGFloat = 280

    var body: some View {
        if let image {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: size - 32, height: size - 32)
                .padding(16)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "qrcode")
                .font(.system(size: 48))
                .foregroundStyle(Color.surgTextSecondary.opacity(0.4))
            Text("QR code unavailable")
                .font(.caption)
                .foregroundStyle(Color.surgTextSecondary.opacity(0.6))
        }
        .frame(width: size, height: size)
        .background(Color.surgSurface, in: RoundedRectangle(cornerRadius: 16))
    }
}