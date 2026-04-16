using System;
using System.IO;
using System.IO.Compression;
using System.Text;
using System.Text.Json;
using SurgSignDesktop.Models;

namespace SurgSignDesktop.Services;

/// <summary>
/// Encodes and decodes <see cref="TransferPayload"/> values for QR transfer.
///
/// <para>
/// Emits the <c>SS3:</c> format produced by the iOS <c>CompressionService.encodeNative</c>:
/// JSON (UTF-8, sorted keys, no whitespace) → zlib (RFC 1950) → URL-safe base64 → <c>SS3:</c> prefix.
/// </para>
/// </summary>
public static class CompressionService
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = false,
        Encoder = System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping
    };

    /// <summary>
    /// Encode a payload to a QR-ready <c>SS3:</c> string.
    /// </summary>
    public static string Encode(TransferPayload payload)
    {
        if (payload is null) throw new ArgumentNullException(nameof(payload));

        byte[] jsonBytes = JsonSerializer.SerializeToUtf8Bytes(payload, JsonOptions);
        byte[] compressed = ZlibCompress(jsonBytes);
        string base64 = Convert.ToBase64String(compressed);
        string urlSafe = base64
            .Replace('+', '-')
            .Replace('/', '_')
            .TrimEnd('=');
        return "SS3:" + urlSafe;
    }

    /// <summary>
    /// Decode an <c>SS3:</c> QR string back to a <see cref="TransferPayload"/> (round-trip test).
    /// </summary>
    public static TransferPayload Decode(string qrString)
    {
        if (qrString is null) throw new ArgumentNullException(nameof(qrString));
        if (!qrString.StartsWith("SS3:", StringComparison.Ordinal))
            throw new FormatException("Unrecognized payload format. Expected SS3: prefix.");

        string base64Url = qrString.Substring(4);
        string base64 = base64Url.Replace('-', '+').Replace('_', '/');

        int pad = base64.Length % 4;
        if (pad != 0) base64 = base64.PadRight(base64.Length + (4 - pad), '=');

        byte[] compressed = Convert.FromBase64String(base64);
        byte[] json = ZlibDecompress(compressed);

        var payload = JsonSerializer.Deserialize<TransferPayload>(json, JsonOptions)
            ?? throw new InvalidOperationException("Decoded JSON was null.");
        return payload;
    }

    /// <summary>
    /// Serialize a payload to the canonical compact JSON string (useful for tests / debugging).
    /// </summary>
    public static string SerializeJson(TransferPayload payload) =>
        JsonSerializer.Serialize(payload, JsonOptions);

    private static byte[] ZlibCompress(byte[] data)
    {
        using var output = new MemoryStream();
        // ZLibStream emits an RFC 1950 stream with a 0x78 header — matches iOS COMPRESSION_ZLIB.
        using (var zlib = new ZLibStream(output, CompressionLevel.Optimal, leaveOpen: true))
        {
            zlib.Write(data, 0, data.Length);
        }
        return output.ToArray();
    }

    private static byte[] ZlibDecompress(byte[] data)
    {
        using var input = new MemoryStream(data);
        using var zlib = new ZLibStream(input, CompressionMode.Decompress);
        using var output = new MemoryStream();
        zlib.CopyTo(output);
        return output.ToArray();
    }
}
