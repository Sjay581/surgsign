import SwiftUI
import SwiftData

/// Confirmation screen shown after a successful QR code scan.
///
/// Displays the decoded handoff metadata and a preview of patient names,
/// allowing the user to confirm or cancel the import.
struct ScanPreviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let payload: TransferPayload
    let onImport: () -> Void

    @State private var hasImported = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surgBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        successIcon
                        metadataSection
                        patientPreviewList
                        importButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Scan Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.surgSurface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.surgTextSecondary)
                }
            }
        }
    }

    // MARK: - Success Icon

    private var successIcon: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.surgGreen)
                .symbolEffect(.bounce, value: true)

            Text("Handoff Decoded")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.surgText)
        }
        .padding(.top, 8)
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(spacing: 12) {
            metadataRow(icon: "stethoscope", label: "Service", value: payload.svc)
            metadataRow(icon: "clock", label: "From Shift", value: payload.from)
            metadataRow(icon: "person.2", label: "Patients", value: "\(payload.pts.count)")
        }
        .padding(16)
        .background(Color.surgSurface, in: RoundedRectangle(cornerRadius: 14))
    }

    private func metadataRow(icon: String, label: String, value: String) -> some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(Color.surgAccent)
                    .frame(width: 24)

                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(Color.surgTextSecondary)
            }

            Spacer()

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.surgText)
        }
    }

    // MARK: - Patient Preview List

    private var patientPreviewList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Patients")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.surgTextSecondary)
                .textCase(.uppercase)
                .padding(.bottom, 10)

            ForEach(Array(payload.pts.enumerated()), id: \.element.id) { index, patient in
                patientPreviewRow(patient: patient)

                if index < payload.pts.count - 1 {
                    Divider()
                        .background(Color.surgBorder)
                }
            }
        }
        .padding(16)
        .background(Color.surgSurface, in: RoundedRectangle(cornerRadius: 14))
    }

    private func patientPreviewRow(patient: TransferPayload.PatientDTO) -> some View {
        HStack(spacing: 12) {
            priorityDot(for: patient.pr)

            VStack(alignment: .leading, spacing: 2) {
                Text(patient.n)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.surgText)
                    .lineLimit(1)

                if !patient.dx.isEmpty {
                    Text(patient.dx)
                        .font(.caption)
                        .foregroundStyle(Color.surgTextSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if !patient.r.isEmpty {
                Text(patient.r)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.surgAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.surgAccent.opacity(0.12), in: Capsule())
            }
        }
        .padding(.vertical, 8)
    }

    private func priorityDot(for rawPriority: String) -> some View {
        let priority = Priority(rawValue: rawPriority) ?? .stable
        return Circle()
            .fill(priority.color)
            .frame(width: 8, height: 8)
    }

    // MARK: - Import Button

    private var importButton: some View {
        VStack(spacing: 12) {
            Button {
                hasImported = true
                onImport()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.subheadline.weight(.semibold))
                    Text("Load Patients")
                        .font(.headline)
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.surgAccent, in: RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.surgAccent.opacity(0.3), radius: 12, y: 6)
            }
            .disabled(hasImported)
            .opacity(hasImported ? 0.5 : 1.0)

            if hasImported {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                    Text("Patients imported successfully")
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(Color.surgGreen)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasImported)
    }
}