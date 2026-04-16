import Testing
import Foundation
@testable import SurgSign

@Suite("TransferPayload")
struct TransferPayloadTests {

    private static func samplePatient(
        id: String = "p1",
        tasks: [PatientTransferData.TaskTransferData] = []
    ) -> PatientTransferData {
        PatientTransferData(
            id: id,
            name: "Doe, Jane",
            mrn: "MRN-123",
            room: "4A",
            surgeon: "Dr. Smith",
            diagnosis: "Appendicitis",
            procedure: "Appendectomy",
            surgeryDate: "2026-04-15",
            codeStatus: "Full Code",
            allergies: "PCN",
            priority: "high",
            notes: "NPO",
            tasks: tasks
        )
    }

    @Test("build populates all fields")
    func buildPopulatesFields() {
        let task = PatientTransferData.TaskTransferData(id: "t1", text: "Draw labs", isDone: true)
        let p = Self.samplePatient(tasks: [task])
        let payload = TransferPayload.build(patients: [p], serviceName: "Ortho", shift: "AM")

        #expect(payload.v == 2)
        #expect(payload.svc == "Ortho")
        #expect(payload.from == "AM")
        #expect(payload.pts.count == 1)

        let dto = payload.pts[0]
        #expect(dto.id == "p1")
        #expect(dto.n == "Doe, Jane")
        #expect(dto.m == "MRN-123")
        #expect(dto.r == "4A")
        #expect(dto.s == "Dr. Smith")
        #expect(dto.dx == "Appendicitis")
        #expect(dto.px == "Appendectomy")
        #expect(dto.sd == "2026-04-15")
        #expect(dto.cs == "Full Code")
        #expect(dto.al == "PCN")
        #expect(dto.pr == "high")
        #expect(dto.nt == "NPO")
        #expect(dto.issues.count == 1)
        #expect(dto.issues[0].id == "t1")
        #expect(dto.issues[0].t == "Draw labs")
        #expect(dto.issues[0].d == 1)
    }

    @Test("jsonData round-trip preserves data")
    func jsonRoundTrip() throws {
        let task = PatientTransferData.TaskTransferData(id: "t1", text: "Draw labs", isDone: false)
        let payload = TransferPayload.build(
            patients: [Self.samplePatient(tasks: [task])],
            serviceName: "Ortho",
            shift: "AM"
        )

        let data = try payload.jsonData()
        let decoded = try TransferPayload.from(jsonData: data)

        #expect(decoded.v == payload.v)
        #expect(decoded.svc == payload.svc)
        #expect(decoded.from == payload.from)
        #expect(decoded.pts.count == 1)
        #expect(decoded.pts[0].id == "p1")
        #expect(decoded.pts[0].issues.count == 1)
        #expect(decoded.pts[0].issues[0].d == 0)
    }

    @Test("jsonString uses PWA-compatible keys")
    func jsonStringUsesPWAKeys() throws {
        let task = PatientTransferData.TaskTransferData(id: "t1", text: "Labs", isDone: true)
        let payload = TransferPayload.build(
            patients: [Self.samplePatient(tasks: [task])],
            serviceName: "Gen",
            shift: "PM"
        )
        let json = try payload.jsonString()

        #expect(json.contains("\"v\":2"))
        #expect(json.contains("\"is\":"))
        #expect(!json.contains("\"issues\":"))
        #expect(json.contains("\"n\":"))
        #expect(json.contains("\"m\":"))
        #expect(json.contains("\"sd\":"))
    }

    @Test("empty patients array round-trips")
    func emptyPatientsRoundTrip() throws {
        let payload = TransferPayload.build(patients: [], serviceName: "X", shift: "Y")
        let data = try payload.jsonData()
        let decoded = try TransferPayload.from(jsonData: data)
        #expect(decoded.pts.isEmpty)
        #expect(decoded.svc == "X")
        #expect(decoded.from == "Y")
    }

    @Test("decoding tolerates unknown top-level keys")
    func unknownKeysIgnored() throws {
        let json = #"{"v":2,"svc":"A","from":"B","pts":[],"extra":"x"}"#
        let decoded = try TransferPayload.from(jsonString: json)
        #expect(decoded.v == 2)
        #expect(decoded.svc == "A")
        #expect(decoded.from == "B")
        #expect(decoded.pts.isEmpty)
    }
}
