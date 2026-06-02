import Foundation
import SwiftData

/// Service responsible for exporting the current patient list to a JSON file
/// (for sharing via the system share sheet) and importing a previously-exported
/// file back into a `ModelContext`.
///
/// Import is additive — existing patients are preserved. Incoming patients are
/// assigned fresh `UUID`s to avoid `@Attribute(.unique)` collisions with any
/// already-present rows that happen to share an id.
struct ExportImportService {

    // MARK: - Export

    /// Exports the given `Patient` list to a pretty-printed JSON file in the
    /// system temporary directory and returns the resulting file URL.
    ///
    /// Callers are expected to present a `UIActivityViewController` (share
    /// sheet) with the returned URL.
    ///
    /// - Parameters:
    ///   - patients: SwiftData `Patient` models to serialize.
    ///   - serviceName: Current surgical service name.
    ///   - shift: Shift label ("AM" / "PM").
    /// - Returns: URL pointing to a file named
    ///   `surgsign-export-<timestamp>.json` inside the temporary directory.
    static func exportJSON(
        patients: [Patient],
        serviceName: String,
        shift: String
    ) throws -> URL {
        let transferData = patients.map { patient -> PatientTransferData in
            let surgeryDateString: String
            if let date = patient.surgeryDate {
                surgeryDateString = Self.isoFormatter.string(from: date)
            } else {
                surgeryDateString = ""
            }

            let tasks = patient.tasks
                .sorted { $0.sortOrder < $1.sortOrder }
                .map { task in
                    PatientTransferData.TaskTransferData(
                        id: task.id.uuidString,
                        text: task.text,
                        isDone: task.isDone
                    )
                }

            return PatientTransferData(
                id: patient.id.uuidString,
                name: patient.name,
                mrn: patient.mrn,
                room: patient.room,
                surgeon: patient.surgeon,
                diagnosis: patient.diagnosis,
                procedure: patient.procedure,
                surgeryDate: surgeryDateString,
                codeStatus: patient.codeStatusRaw,
                allergies: patient.allergies,
                priority: patient.priorityRaw,
                notes: patient.notes,
                tasks: tasks
            )
        }

        let payload = TransferPayload.build(
            patients: transferData,
            serviceName: serviceName,
            shift: shift
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data: Data
        do {
            data = try encoder.encode(payload)
        } catch {
            throw ExportImportError.writeFailed
        }

        let timestamp = Self.timestampFormatter.string(from: Date())
        let filename = "surgsign-export-\(timestamp).json"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)

        do {
            try data.write(to: url, options: [.atomic])
        } catch {
            throw ExportImportError.writeFailed
        }

        return url
    }

    // MARK: - Import

    /// Imports patients from a previously-exported JSON file into the given
    /// `ModelContext`. Existing patients are left untouched — this is a merge.
    ///
    /// - Parameters:
    ///   - url: URL to the JSON file. If this came from a document picker the
    ///     method will handle security-scoped access automatically.
    ///   - context: The `ModelContext` to insert the imported patients into.
    /// - Returns: The number of patients successfully imported.
    @discardableResult
    static func importJSON(from url: URL, into context: ModelContext) throws -> Int {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ExportImportError.readFailed
        }

        let payload: TransferPayload
        do {
            payload = try TransferPayload.from(jsonData: data)
        } catch {
            throw ExportImportError.decodeFailed(error)
        }

        var importedCount = 0

        for dto in payload.pts {
            let surgeryDate: Date?
            if dto.sd.isEmpty {
                surgeryDate = nil
            } else {
                surgeryDate = Self.isoFormatter.date(from: dto.sd)
            }

            let codeStatus = CodeStatus(rawValue: dto.cs) ?? .fullCode
            let priority = Priority(rawValue: dto.pr) ?? .stable

            let patient = Patient(
                name: dto.n,
                mrn: dto.m,
                room: dto.r,
                surgeon: dto.s,
                diagnosis: dto.dx,
                procedure: dto.px,
                surgeryDate: surgeryDate,
                codeStatus: codeStatus,
                allergies: dto.al,
                priority: priority,
                notes: dto.nt,
                sortOrder: importedCount
            )

            context.insert(patient)

            for (index, taskDTO) in dto.issues.enumerated() {
                let task = PatientTask(
                    text: taskDTO.t,
                    isDone: taskDTO.d == 1,
                    sortOrder: index
                )
                task.patient = patient
                context.insert(task)
            }

            importedCount += 1
        }

        do {
            try context.save()
        } catch {
            throw ExportImportError.writeFailed
        }

        return importedCount
    }

    // MARK: - Formatters

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmmss"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()
}

// MARK: - Errors

enum ExportImportError: LocalizedError {
    case readFailed
    case writeFailed
    case decodeFailed(Error)

    var errorDescription: String? {
        switch self {
        case .readFailed:
            return "Failed to read the selected file."
        case .writeFailed:
            return "Failed to write the export file."
        case .decodeFailed(let error):
            return "Failed to decode the file: \(error.localizedDescription)"
        }
    }
}