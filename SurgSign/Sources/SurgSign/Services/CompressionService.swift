import Foundation
import Compression

// MARK: - Compression Service

/// Encodes and decodes `TransferPayload` values for QR code and peer-to-peer
/// transfer.  Supports two wire formats:
///
/// - **SS2** — LZ-String `compressToEncodedURIComponent`, compatible with the
///   existing PWA.
/// - **SS3** — zlib (RFC 1950) compressed JSON encoded as URL-safe Base64,
///   used for iOS-to-iOS transfers where PWA interop is not required.
struct CompressionService {

    // MARK: - Public API

    /// Encode a payload to a QR-ready string using the SS2 (LZ-String) format
    /// for maximum cross-platform compatibility with the PWA.
    static func encode(_ payload: TransferPayload) throws -> String {
        let json = try payload.jsonString()
        let compressed = LZString.compressToEncodedURIComponent(json)
        return "SS2:" + compressed
    }

    /// Encode a payload using the SS3 (zlib + Base64) format.
    /// Produces smaller output on iOS and avoids the complexity of LZ-String,
    /// but is not compatible with the PWA.
    static func encodeNative(_ payload: TransferPayload) throws -> String {
        let json = try payload.jsonData()
        let compressed = try zlibCompress(json)
        let base64 = compressed.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "SS3:" + base64
    }

    /// Decode a QR string back to a `TransferPayload`.
    /// Automatically detects SS2 vs SS3 format from the prefix.
    static func decode(_ qrString: String) throws -> TransferPayload {
        if qrString.hasPrefix("SS2:") {
            let compressed = String(qrString.dropFirst(4))
            guard let json = LZString.decompressFromEncodedURIComponent(compressed) else {
                throw CompressionError.decompressionFailed
            }
            return try TransferPayload.from(jsonString: json)
        } else if qrString.hasPrefix("SS3:") {
            let base64URL = String(qrString.dropFirst(4))
            let base64 = base64URL
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
                .padding(toLength: ((base64URL.count + 3) / 4) * 4,
                         withPad: "=", startingAt: 0)
            guard let compressed = Data(base64Encoded: base64) else {
                throw CompressionError.invalidBase64
            }
            let json = try zlibDecompress(compressed)
            return try TransferPayload.from(jsonData: json)
        } else {
            throw CompressionError.unknownFormat
        }
    }

    // MARK: - zlib Helpers

    private static func zlibCompress(_ data: Data) throws -> Data {
        let sourceSize = data.count
        guard sourceSize > 0 else { return Data() }

        // Worst-case output size: source + overhead.
        let destinationSize = sourceSize + 512
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationSize)
        defer { destinationBuffer.deallocate() }

        let compressedSize = data.withUnsafeBytes { (sourcePtr: UnsafeRawBufferPointer) -> Int in
            guard let baseAddress = sourcePtr.baseAddress else { return 0 }
            return compression_encode_buffer(
                destinationBuffer, destinationSize,
                baseAddress.assumingMemoryBound(to: UInt8.self), sourceSize,
                nil,
                COMPRESSION_ZLIB
            )
        }

        guard compressedSize > 0 else {
            throw CompressionError.compressionFailed
        }

        return Data(bytes: destinationBuffer, count: compressedSize)
    }

    private static func zlibDecompress(_ data: Data) throws -> Data {
        let sourceSize = data.count
        guard sourceSize > 0 else { return Data() }

        // Start with a generous destination buffer; grow if needed.
        var destinationSize = sourceSize * 8
        var result = Data()

        while true {
            let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationSize)
            defer { destinationBuffer.deallocate() }

            let decompressedSize = data.withUnsafeBytes { (srcPtr: UnsafeRawBufferPointer) -> Int in
                guard let base = srcPtr.baseAddress else { return 0 }
                return compression_decode_buffer(
                    destinationBuffer, destinationSize,
                    base.assumingMemoryBound(to: UInt8.self), sourceSize,
                    nil,
                    COMPRESSION_ZLIB
                )
            }

            if decompressedSize == 0 {
                throw CompressionError.decompressionFailed
            }

            if decompressedSize < destinationSize || destinationSize > 10_000_000 {
                result = Data(bytes: destinationBuffer, count: decompressedSize)
                break
            }

            // Buffer was too small — double and retry.
            destinationSize *= 2
        }

        return result
    }
}

// MARK: - Errors

enum CompressionError: LocalizedError {
    case compressionFailed
    case decompressionFailed
    case invalidBase64
    case unknownFormat

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress the payload data."
        case .decompressionFailed:
            return "Failed to decompress the payload data."
        case .invalidBase64:
            return "The Base64 data in the payload is invalid."
        case .unknownFormat:
            return "Unrecognized payload format. Expected SS2: or SS3: prefix."
        }
    }
}

// MARK: - LZ-String

/// A faithful Swift port of lz-string's `compressToEncodedURIComponent` /
/// `decompressFromEncodedURIComponent`.
///
/// Reference implementation: https://github.com/pieroxy/lz-string
///
/// The algorithm is an LZW-family compressor that works on 16-bit Unicode
/// code units and outputs variable-width bit groups.  The
/// "EncodedURIComponent" variant packs bits into a 6-bit base using the
/// alphabet `ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-`
/// with `$` used for final-group padding.
enum LZString {

    // The 64-character URI-safe alphabet used by lz-string.
    private static let keyStrUriSafe =
        Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-")

    // Reverse lookup: character -> index.
    private static let keyStrUriSafeMap: [Character: Int] = {
        var map = [Character: Int]()
        for (i, c) in keyStrUriSafe.enumerated() {
            map[c] = i
        }
        map["$"] = 64  // padding sentinel
        return map
    }()

    // MARK: - Public

    static func compressToEncodedURIComponent(_ input: String) -> String {
        guard !input.isEmpty else { return "" }
        let compressed = compress(input, bitsPerChar: 6, getCharFromInt: { keyStrUriSafe[$0] })
        // Pad so length is a multiple of 4 with "$".
        switch compressed.count % 4 {
        case 0:  return compressed
        case 1:  return compressed + "$$$"
        case 2:  return compressed + "$$"
        case 3:  return compressed + "$"
        default: return compressed
        }
    }

    static func decompressFromEncodedURIComponent(_ input: String) -> String? {
        guard !input.isEmpty else { return "" }
        // Strip padding.
        let stripped = input.replacingOccurrences(of: "$", with: " ")
        return decompress(stripped.count, resetValue: 32, getNextValue: { index in
            let chars = Array(stripped)
            guard index < chars.count else { return 0 }
            let c = chars[index]
            if c == " " { return 64 } // padding was space-replaced
            return keyStrUriSafeMap[c] ?? 0
        })
    }

    // MARK: - Core Compression

    private static func compress(
        _ uncompressed: String,
        bitsPerChar: Int,
        getCharFromInt: (Int) -> Character
    ) -> String {

        var context_dictionary = [String: Int]()
        var context_dictionaryToCreate = Set<String>()
        var context_wc = ""
        var context_w = ""
        var context_enlargeIn = 2  // triggers enlargement when dictionary hits this
        var context_dictSize = 3
        var context_numBits = 2
        var context_data = [Character]()
        var context_data_val = 0
        var context_data_position = 0

        // Inline helper: write `numBits` low bits of `value` into the output.
        func writeBits(_ value: Int, _ numBits: Int) {
            var v = value
            for _ in 0..<numBits {
                context_data_val = (context_data_val << 1) | (v & 1)
                if context_data_position == bitsPerChar - 1 {
                    context_data_position = 0
                    context_data.append(getCharFromInt(context_data_val))
                    context_data_val = 0
                } else {
                    context_data_position += 1
                }
                v >>= 1
            }
        }

        let chars = Array(uncompressed.unicodeScalars).map { String($0) }

        for i in 0..<chars.count {
            let context_c = chars[i]
            if context_dictionary[context_c] == nil {
                context_dictionary[context_c] = context_dictSize
                context_dictSize += 1
                context_dictionaryToCreate.insert(context_c)
            }

            context_wc = context_w + context_c
            if context_dictionary[context_wc] != nil {
                context_w = context_wc
            } else {
                if context_dictionaryToCreate.contains(context_w) {
                    let firstScalar = context_w.unicodeScalars.first!.value
                    if firstScalar < 256 {
                        writeBits(0, context_numBits)
                        writeBits(Int(firstScalar), 8)
                    } else {
                        writeBits(1, context_numBits)
                        writeBits(Int(firstScalar), 16)
                    }
                    context_enlargeIn -= 1
                    if context_enlargeIn == 0 {
                        context_enlargeIn = 1 << context_numBits
                        context_numBits += 1
                    }
                    context_dictionaryToCreate.remove(context_w)
                } else {
                    writeBits(context_dictionary[context_w]!, context_numBits)
                }
                context_enlargeIn -= 1
                if context_enlargeIn == 0 {
                    context_enlargeIn = 1 << context_numBits
                    context_numBits += 1
                }
                // Add wc to the dictionary.
                context_dictionary[context_wc] = context_dictSize
                context_dictSize += 1
                context_w = context_c
            }
        }

        // Output the code for w.
        if !context_w.isEmpty {
            if context_dictionaryToCreate.contains(context_w) {
                let firstScalar = context_w.unicodeScalars.first!.value
                if firstScalar < 256 {
                    writeBits(0, context_numBits)
                    writeBits(Int(firstScalar), 8)
                } else {
                    writeBits(1, context_numBits)
                    writeBits(Int(firstScalar), 16)
                }
                context_enlargeIn -= 1
                if context_enlargeIn == 0 {
                    context_enlargeIn = 1 << context_numBits
                    context_numBits += 1
                }
                context_dictionaryToCreate.remove(context_w)
            } else {
                writeBits(context_dictionary[context_w]!, context_numBits)
            }
            context_enlargeIn -= 1
            if context_enlargeIn == 0 {
                // Not strictly needed at end, but matches reference.
                context_numBits += 1
            }
        }

        // Mark the end of the stream (value 2).
        writeBits(2, context_numBits)

        // Flush remaining bits.
        while true {
            context_data_val = context_data_val << 1
            if context_data_position == bitsPerChar - 1 {
                context_data.append(getCharFromInt(context_data_val))
                break
            } else {
                context_data_position += 1
            }
        }

        return String(context_data)
    }

    // MARK: - Core Decompression

    private static func decompress(
        _ length: Int,
        resetValue: Int,
        getNextValue: (Int) -> Int
    ) -> String? {

        var dictionary = [Int: String]()
        var enlargeIn = 4
        var dictSize = 4
        var numBits = 3
        var entry = ""
        var result = ""
        var w = ""

        // Bit reader state.
        var dataVal = getNextValue(0)
        var dataPosition = resetValue
        var dataIndex = 1

        func readBits(_ maxPower: Int) -> Int {
            var bits = 0
            var power = 1
            while power != maxPower {
                let resb = dataVal & dataPosition
                dataPosition >>= 1
                if dataPosition == 0 {
                    dataPosition = resetValue
                    dataVal = getNextValue(dataIndex)
                    dataIndex += 1
                }
                bits |= (resb > 0 ? 1 : 0) * power
                power <<= 1
            }
            return bits
        }

        // Seed the dictionary with the three special entries.
        for i in 0..<3 {
            dictionary[i] = String(repeating: "\0", count: 0) // placeholder
        }

        // Read the first token to determine what it is.
        let firstBits = readBits(4) // 2 bits for numBits=3 would be power-of-2=4
        switch firstBits {
        case 0:
            let charCode = readBits(256)  // 8 bits
            let c = String(Unicode.Scalar(UInt32(charCode))!)
            dictionary[3] = c
            dictSize = 4
            w = c
            result.append(c)
        case 1:
            let charCode = readBits(65536) // 16 bits
            guard let scalar = Unicode.Scalar(UInt32(charCode)) else { return nil }
            let c = String(scalar)
            dictionary[3] = c
            dictSize = 4
            w = c
            result.append(c)
        case 2:
            // Empty string.
            return ""
        default:
            return nil
        }

        enlargeIn = 4 // reset after first token
        numBits = 3

        while true {
            let cc = readBits(1 << numBits)

            switch cc {
            case 0:
                let charCode = readBits(256)
                let s = String(Unicode.Scalar(UInt32(charCode))!)
                dictionary[dictSize] = s
                dictSize += 1
                entry = s
                enlargeIn -= 1
            case 1:
                let charCode = readBits(65536)
                guard let scalar = Unicode.Scalar(UInt32(charCode)) else { return nil }
                let s = String(scalar)
                dictionary[dictSize] = s
                dictSize += 1
                entry = s
                enlargeIn -= 1
            case 2:
                // End of stream.
                return result
            default:
                if let existing = dictionary[cc] {
                    entry = existing
                } else if cc == dictSize {
                    entry = w + String(w.first!)
                } else {
                    return nil
                }
            }

            result.append(entry)

            // Add w + entry[0] to the dictionary.
            dictionary[dictSize] = w + String(entry.first!)
            dictSize += 1
            enlargeIn -= 1

            if enlargeIn == 0 {
                enlargeIn = 1 << numBits
                numBits += 1
            }

            w = entry
        }
    }
}
