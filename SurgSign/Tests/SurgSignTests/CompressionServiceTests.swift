import Testing
import Foundation
@testable import SurgSign

@Suite("CompressionService")
struct CompressionServiceTests {

    // MARK: - Fixtures

    private static func patient(_ id: String) -> PatientTransferData {
        PatientTransferData(
            id: id,
            name: "Patient \(id)",
            mrn: "MRN-\(id)",
            room: "R\(id)",
            surgeon: "Dr. S",
            diagnosis: "Dx",
            procedure: "Px",
            surgeryDate: "2026-04-15",
            codeStatus: "Full Code",
            allergies: "NKDA",
            priority: "medium",
            notes: "n",
            tasks: [
                .init(id: "t-\(id)", text: "Task for \(id)", isDone: false)
            ]
        )
    }

    private static func samplePayload(count: Int = 1) -> TransferPayload {
        let pts = (0..<count).map { patient("\($0)") }
        return TransferPayload.build(patients: pts, serviceName: "Ortho", shift: "AM")
    }

    // MARK: - SS2 round-trip

    @Test("SS2 encode/decode round-trip")
    func ss2RoundTrip() throws {
        let payload = Self.samplePayload(count: 2)
        let encoded = try CompressionService.encode(payload)
        #expect(encoded.hasPrefix("SS2:"))

        let decoded = try CompressionService.decode(encoded)
        #expect(decoded.v == payload.v)
        #expect(decoded.svc == payload.svc)
        #expect(decoded.from == payload.from)
        #expect(decoded.pts.count == payload.pts.count)
        #expect(decoded.pts.first?.id == payload.pts.first?.id)
    }

    // MARK: - SS3 round-trip

    @Test("SS3 encodeNative/decode round-trip")
    func ss3RoundTrip() throws {
        let payload = Self.samplePayload(count: 2)
        let encoded = try CompressionService.encodeNative(payload)
        #expect(encoded.hasPrefix("SS3:"))

        let decoded = try CompressionService.decode(encoded)
        #expect(decoded.v == payload.v)
        #expect(decoded.pts.count == payload.pts.count)
        #expect(decoded.pts.first?.m == payload.pts.first?.m)
    }

    // MARK: - Error cases

    @Test("SS3 prefix wrapping SS2 body throws")
    func ss3PrefixOnSS2BodyThrows() throws {
        let payload = Self.samplePayload()
        let ss2 = try CompressionService.encode(payload)
        let body = String(ss2.dropFirst(4))
        let mislabeled = "SS3:" + body
        #expect(throws: (any Error).self) {
            _ = try CompressionService.decode(mislabeled)
        }
    }

    @Test("Garbage string with no prefix throws unknownFormat")
    func garbageThrowsUnknownFormat() {
        #expect(throws: CompressionError.unknownFormat) {
            _ = try CompressionService.decode("not-a-real-payload")
        }
    }

    @Test("SS3 with malformed base64 throws invalidBase64")
    func ss3MalformedBase64() {
        // A character outside the base64 / URL-safe alphabet.
        #expect(throws: CompressionError.invalidBase64) {
            _ = try CompressionService.decode("SS3:!!!not-base64!!!")
        }
    }

    // MARK: - LZString helpers

    @Test("LZString.compressToEncodedURIComponent('') returns empty")
    func lzEmpty() {
        #expect(LZString.compressToEncodedURIComponent("") == "")
    }

    @Test("LZString round-trip for a small string")
    func lzSmallRoundTrip() throws {
        let original = "hello lz-string"
        let compressed = LZString.compressToEncodedURIComponent(original)
        #expect(!compressed.isEmpty)
        let decompressed = try #require(LZString.decompressFromEncodedURIComponent(compressed))
        #expect(decompressed == original)
    }

    // MARK: - Size comparison (informational)

    @Test("SS3 is smaller than SS2 for a larger payload")
    func ss3SmallerThanSS2() throws {
        let payload = Self.samplePayload(count: 4)
        let ss2 = try CompressionService.encode(payload)
        let ss3 = try CompressionService.encodeNative(payload)
        #expect(ss3.count < ss2.count)
    }
}
