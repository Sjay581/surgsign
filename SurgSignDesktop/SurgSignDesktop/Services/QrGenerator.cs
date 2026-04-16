using System;
using System.IO;
using System.Windows.Media.Imaging;
using QRCoder;

namespace SurgSignDesktop.Services;

/// <summary>
/// Generates a QR code bitmap from a string payload.
/// </summary>
public static class QrGenerator
{
    /// <summary>
    /// Build a <see cref="BitmapSource"/> containing a QR code for the given payload.
    /// </summary>
    /// <param name="payload">The string to encode.</param>
    /// <param name="eccLevel">Error-correction level. Lower levels fit more data per QR.</param>
    /// <param name="pixelsPerModule">Module size in pixels (higher = bigger bitmap).</param>
    public static BitmapSource Generate(
        string payload,
        QRCodeGenerator.ECCLevel eccLevel = QRCodeGenerator.ECCLevel.M,
        int pixelsPerModule = 10)
    {
        if (payload is null) throw new ArgumentNullException(nameof(payload));

        using var generator = new QRCodeGenerator();
        using var data = generator.CreateQrCode(payload, eccLevel);
        using var png = new PngByteQRCode(data);
        byte[] bytes = png.GetGraphic(pixelsPerModule);

        var bitmap = new BitmapImage();
        using var stream = new MemoryStream(bytes);
        bitmap.BeginInit();
        bitmap.CacheOption = BitmapCacheOption.OnLoad;
        bitmap.StreamSource = stream;
        bitmap.EndInit();
        bitmap.Freeze();
        return bitmap;
    }
}
