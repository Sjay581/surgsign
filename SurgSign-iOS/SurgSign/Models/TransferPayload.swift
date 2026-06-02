import Foundation

// MARK: - Transfer Payload

/// A pure Codable struct representing the v2 QR transfer format.
/// Matches the PWA's JSON encoding exactly for cross-platform compatibility.
/// This struct has no SwiftData dependency — ViewModels bridge between
/// SwiftData `@Model` objects and this DTO layer.
struct TransferPayload: Codable, Sendable {
    let v: Int
    let svc: String
    let from: String
    let pts: [PatientDTO]

    // MARK: - Patient DTO

    struct PatientDTO: Codable, Sendable {
        let id: String
        let n: String    // "Last, First"
        let m: String    // MRN
        let r: String    // room
        let s: String    // surgeon
        let dx: String   // diagnosis
        let px: String   // procedure
        let sd: String   // surgery date (ISO-8601 date string)
        let cs: String   // code status raw value
        let al: String   // allergies
        let pr: String   // priority raw value
        let nt: String   // notes
        let issues: [TaskDTO]

        enum CodingKeys: String, CodingKey {
            case id, n, m, r, s, dx, px, sd, cs, al, pr, nt
            case issues = "is"
        }

        // MARK: - Task DTO

        struct TaskDTO: Codable, Sendable {
            let id: String
            let t: String   // text
            let d: Int      // 0 = not done, 1 = done
        }
    }

    // MARK: - Factory

    /// Build a transfer payload from an array of `PatientTransferData`.
    static func build(
        patients: [PatientTransferData],
        serviceName: String,
        shift: String
    ) -> TransferPayload {
        let dtos = patients.map { p in
            PatientDTO(
                id: p.id,
                n: p.name,
                m: p.mrn,
                r: p.room,
                s: p.surgeon,
                dx: p.diagnosis,
                px: p.procedure,
                sd: p.surgeryDate,
                cs: p.codeStatus,
                al: p.allergies,
                pr: p.priority,
                nt: p.notes,
                issues: p.tasks.map { task in
                    PatientDTO.TaskDTO(
                        id: task.id,
                        t: task.text,
                        d: task.isDone ? 1 : 0
                    )
                }
            )
        }
        return TransferPayload(v: 2, svc: serviceName, from: shift, pts: dtos)
    }

    // MARK: - JSON Helpers

    /// Encode this payload to compact JSON data (no extra whitespace).
    func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }

    /// Encode this payload to a compact JSON string.
    func jsonString() throws -> String {
        let data = try jsonData()
        guard let string = String(data: data, encoding: .utf8) else {
            throw TransferPayloadError.encodingFailed
        }
        return string
    }

    /// Decode a `TransferPayload` from JSON data.
    static func from(jsonData data: Data) throws -> TransferPayload {
        let decoder = JSONDecoder()
        return try decoder.decode(TransferPayload.self, from: data)
    }

    /// Decode a `TransferPayload` from a JSON string.
    static func from(jsonString string: String) throws -> TransferPayload {
        guard let data = string.data(using: .utf8) else {
            throw TransferPayloadError.decodingFailed
        }
        return try from(jsonData: data)
    }
}

// MARK: - PatientTransferData

/// A lightweight, SwiftData-free struct used to pass patient information
/// into the services layer. ViewModels create these from `@Model` objects.
struct PatientTransferData: Sendable {
    let id: String
    let name: String
    let mrn: String
    let room: String
    let surgeon: String
    let diagnosis: String
    let procedure: String
    let surgeryDate: String
    let codeStatus: String
    let allergies: String
    let priority: String
    let notes: String
    let tasks: [TaskTransferData]

    struct TaskTransferData: Sendable {
        let id: String
        let text: String
        let isDone: Bool
    }
}

// MARK: - Errors

enum TransferPayloadError: LocalizedError {
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode the transfer payload to JSON."
        case .decodingFailed:
            return "Failed to decode the transfer payload from JSON."
        }
    }
}