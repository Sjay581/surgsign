import Foundation
import SwiftData
import SwiftUI

/// View model driving the main patient list screen.
///
/// Handles sorting, filtering, deletion, and demo-data seeding.
@Observable
final class PatientListViewModel {

    // MARK: - Published State

    var searchText: String = ""
    var showingAddForm: Bool = false
    var showingHandoff: Bool = false
    var showingScanner: Bool = false
    var editingPatient: Patient? = nil
    var showingDeleteConfirmation: Bool = false
    var patientToDelete: Patient? = nil

    // MARK: - Sorting & Filtering

    /// Returns patients sorted by priority (highest first), then alphabetically by name.
    func sortedPatients(_ patients: [Patient]) -> [Patient] {
        patients.sorted { lhs, rhs in
            if lhs.priority.sortOrder != rhs.priority.sortOrder {
                return lhs.priority.sortOrder < rhs.priority.sortOrder
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    /// Returns patients whose name, MRN, room, surgeon, or diagnosis matches the
    /// current `searchText` (case-insensitive). An empty search text returns all patients.
    func filteredPatients(_ patients: [Patient]) -> [Patient] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sortedPatients(patients) }

        let lowered = query.lowercased()
        let filtered = patients.filter { patient in
            patient.name.lowercased().contains(lowered)
                || patient.mrn.lowercased().contains(lowered)
                || patient.room.lowercased().contains(lowered)
                || patient.surgeon.lowercased().contains(lowered)
                || patient.diagnosis.lowercased().contains(lowered)
        }
        return sortedPatients(filtered)
    }

    // MARK: - Actions

    /// Deletes a patient from the persistent store.
    func deletePatient(_ patient: Patient, context: ModelContext) {
        context.delete(patient)
        try? context.save()
        patientToDelete = nil
        showingDeleteConfirmation = false
    }

    // MARK: - Demo Data

    /// Seeds four demo patients into the database when it is empty.
    /// Dates are calculated relative to today so that POD values remain meaningful.
    func seedDemoDataIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Patient>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Helper to offset dates from today.
        func daysAgo(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: -days, to: today)!
        }

        // 1. Morrison, James R.
        let morrison = Patient(
            name: "Morrison, James R.",
            mrn: "2847193",
            room: "4B-12",
            surgeon: "Dr. Chen",
            diagnosis: "Acute appendicitis",
            procedure: "Laparoscopic appendectomy",
            surgeryDate: daysAgo(1),
            codeStatus: .fullCode,
            allergies: "NKDA",
            priority: .high,
            notes: "Low-grade fever overnight (100.2°F at 02:00). Monitor trend. If temp >101.5°F → blood cultures x2, UA, CXR. Currently on Cefazolin 1g q8h - will complete 24h course then reassess.",
            sortOrder: 0,
            tasks: [
                PatientTask(text: "Check AM labs (CBC, BMP, Lactate)", sortOrder: 0),
                PatientTask(text: "Reassess pain management plan", sortOrder: 1),
                PatientTask(text: "Advance diet as tolerated", sortOrder: 2),
            ]
        )

        // 2. Kowalski, Sandra M.
        let kowalski = Patient(
            name: "Kowalski, Sandra M.",
            mrn: "3912847",
            room: "6A-03",
            surgeon: "Dr. Patel",
            diagnosis: "Choledocholithiasis with cholangitis",
            procedure: "ERCP with sphincterotomy → Lap chole",
            surgeryDate: today,
            codeStatus: .fullCode,
            allergies: "PCN (rash), Sulfa (hives)",
            priority: .medium,
            notes: "Underwent ERCP at 14:00 today, 3 stones extracted. Lap chole planned once inflammation resolves. IV Unasyn 3g q6h. Monitor for post-ERCP pancreatitis signs: increasing abdominal pain, nausea, rising amylase. NPO overnight, reassess in AM.",
            sortOrder: 1,
            tasks: [
                PatientTask(text: "Monitor post-ERCP: amylase/lipase at 6h", sortOrder: 0),
                PatientTask(text: "Strict I&O - foley in place", sortOrder: 1),
                PatientTask(text: "NPO until AM, then clear liquids if tolerating", sortOrder: 2),
            ]
        )

        // 3. Huang, Robert T.
        let huang = Patient(
            name: "Huang, Robert T.",
            mrn: "1738294",
            room: "5C-18",
            surgeon: "Dr. Williams",
            diagnosis: "Sigmoid colon adenocarcinoma",
            procedure: "Low anterior resection with diverting ileostomy",
            surgeryDate: daysAgo(5),
            codeStatus: .dnrDni,
            allergies: "Morphine (nausea)",
            priority: .medium,
            notes: "Family meeting held yesterday. Patient aware of pathology results. Ileostomy output trending down. Diet advanced to low-residue. Wound vac in place over midline incision — change scheduled tomorrow. PT/OT following, patient ambulatory with minimal assistance.",
            sortOrder: 2,
            tasks: [
                PatientTask(text: "Ostomy output q4h - notify if >1500mL/day", sortOrder: 0),
                PatientTask(text: "Check PM BMP for electrolyte monitoring", sortOrder: 1),
                PatientTask(text: "PT/OT eval ordered - encourage ambulation", sortOrder: 2),
            ]
        )

        // 4. Delgado, Maria C.
        let delgado = Patient(
            name: "Delgado, Maria C.",
            mrn: "4628173",
            room: "3A-07",
            surgeon: "Dr. Chen",
            diagnosis: "Incarcerated umbilical hernia",
            procedure: "Open umbilical hernia repair with mesh",
            surgeryDate: daysAgo(3),
            codeStatus: .fullCode,
            allergies: "NKDA",
            priority: .stable,
            notes: "Uncomplicated recovery. Pain well-controlled on PO medications. Tolerating regular diet. Ambulating independently. Wound clean, dry, intact — no signs of infection or seroma. Social work consulted for home health needs.",
            sortOrder: 3,
            tasks: [
                PatientTask(text: "Wound check - monitor for seroma", sortOrder: 0),
                PatientTask(text: "Advance to regular diet", sortOrder: 1),
                PatientTask(text: "Discharge planning - target POD 4", sortOrder: 2),
            ]
        )

        context.insert(morrison)
        context.insert(kowalski)
        context.insert(huang)
        context.insert(delgado)

        try? context.save()
    }
}