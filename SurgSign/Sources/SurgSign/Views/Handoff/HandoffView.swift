import SwiftUI
import SwiftData

/// QR code display screen for outgoing shift handoff, presented as a sheet.
///
/// Generates a QR code encoding the current patient list and displays it
/// alongside payload size information and a peer-transfer fallback.
struct HandoffView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Query private var patients: [Patient]

    @State private var viewModel = HandoffViewModel()
    @State private var multipeerService = MultipeerService()
    @State private var showPeerTransfer = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surgBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        shiftHeader
                        qrSection
                        payloadInfo
                        phiWarningBanner
                        peerTransferButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Shift Handoff")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.surgSurface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.surgTextSecondary)
                            .font(.title3)
                    }
                }
            }
            .onAppear {
                viewModel.generateQR(
                    patients: patients,
                    serviceName: appState.serviceName,
                    shift: appState.shiftLabel
                )
            }
        }
    }

    // MARK: - Shift Header

    private var shiftHeader: some View {
        VStack(spacing: 8) {
            Text(appState.serviceName)
                .font(.headline)
                .foregroundStyle(Color.surgText)

            HStack(spacing: 8) {
                Text(appState.isAMShift ? "AM" : "PM")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(appState.shiftColor)

                Image(systemName: "arrow.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.surgTextSecondary)

                Text(appState.isAMShift ? "PM" : "AM")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(appState.isAMShift ? Color.surgPM : Color.surgAM)
            }

            Text("\(patients.count) patient\(patients.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(Color.surgTextSecondary)
        }
        .padding(.top, 8)
    }

    // MARK: - QR Code Section

    private var qrSection: some View {
        VStack(spacing: 16) {
            if viewModel.isGenerating {
                ProgressView()
                    .tint(Color.surgAccent)
                    .scaleEffect(1.5)
                    .frame(width: 280, height: 280)
            } else if let errorMessage = viewModel.errorMessage {
                errorView(errorMessage)
            } else {
                QRCodeImageView(image: viewModel.qrImage)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.surgRed)
            Text("Generation Failed")
                .font(.headline)
                .foregroundStyle(Color.surgText)
            Text(message)
                .font(.caption)
                .foregroundStyle(Color.surgTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color.surgSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Payload Info

    @ViewBuilder
    private var payloadInfo: some View {
        if !viewModel.isGenerating && viewModel.errorMessage == nil {
            VStack(spacing: 8) {
                let sizeKB = String(format: "%.1f", Double(viewModel.payloadSize) / 1024.0)
                let maxKB = String(format: "%.1f", Double(QRCodeService.qrMaxBytesMediumEC) / 1024.0)

                HStack(spacing: 4) {
                    Image(systemName: "doc.text")
                        .font(.caption)
                    Text("\(sizeKB) KB / \(maxKB) KB")
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(
                    viewModel.isOverQRLimit ? Color.surgRed : Color.surgTextSecondary
                )

                if viewModel.isOverQRLimit {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                        Text("Payload exceeds QR capacity. Use Peer Transfer instead.")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.surgAM)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.surgAM.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - PHI Warning

    private var phiWarningBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.shield.fill")
                .font(.subheadline)
                .foregroundStyle(Color.surgAM)

            Text("This QR code contains patient information. Ensure it is displayed securely.")
                .font(.caption)
                .foregroundStyle(Color.surgTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surgAM.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.surgAM.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Peer Transfer Button

    private var peerTransferButton: some View {
        Button {
            if let data = viewModel.getTransferData(
                patients: patients,
                serviceName: appState.serviceName,
                shift: appState.shiftLabel
            ) {
                multipeerService.startAdvertising(data: data)
                showPeerTransfer = true
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.subheadline)
                Text("Peer Transfer")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(Color.surgAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.surgAccent.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.surgAccent.opacity(0.3), lineWidth: 1)
            )
        }
        .sheet(isPresented: $showPeerTransfer) {
            multipeerService.stop()
        } content: {
            PeerTransferSenderView(multipeerService: multipeerService)
        }
    }
}

// MARK: - Peer Transfer Sender View

/// Minimal sender view that displays the peer transfer state while advertising.
private struct PeerTransferSenderView: View {
    @Bindable var multipeerService: MultipeerService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surgBackground
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    stateIcon
                    stateLabel
                    stateDescription
                }
                .padding(32)
            }
            .navigationTitle("Peer Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.surgSurface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        multipeerService.stop()
                        dismiss()
                    }
                    .foregroundStyle(Color.surgTextSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch multipeerService.state {
        case .advertising:
            ProgressView()
                .tint(Color.surgAccent)
                .scaleEffect(1.5)
        case .connecting:
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.largeTitle)
                .foregroundStyle(Color.surgAM)
                .symbolEffect(.rotate)
        case .connected:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.surgGreen)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.surgRed)
        default:
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.largeTitle)
                .foregroundStyle(Color.surgAccent)
        }
    }

    private var stateLabel: some View {
        Text(stateLabelText)
            .font(.headline)
            .foregroundStyle(Color.surgText)
    }

    private var stateDescription: some View {
        Text(stateDescriptionText)
            .font(.subheadline)
            .foregroundStyle(Color.surgTextSecondary)
            .multilineTextAlignment(.center)
    }

    private var stateLabelText: String {
        switch multipeerService.state {
        case .advertising: return "Waiting for Receiver"
        case .connecting(let name): return "Connecting to \(name)"
        case .connected(let name): return "Sent to \(name)"
        case .failed(let msg): return "Transfer Failed"
        default: return "Peer Transfer"
        }
    }

    private var stateDescriptionText: String {
        switch multipeerService.state {
        case .advertising:
            return "The receiving device should open the scanner and select Peer Transfer to receive data."
        case .connecting:
            return "Establishing secure connection..."
        case .connected:
            return "Patient data has been sent successfully. The receiver can now import the list."
        case .failed(let msg):
            return msg
        default:
            return ""
        }
    }
}

// MARK: - HandoffViewModel

/// View model responsible for generating QR code data from the patient list.
@Observable
final class HandoffViewModel {
    var qrImage: UIImage?
    var payloadSize: Int = 0
    var isOverQRLimit: Bool = false
    var isGenerating: Bool = false
    var errorMessage: String?
    var showPHIWarning: Bool = true

    /// Generates a QR code image encoding all patients for handoff.
    func generateQR(patients: [Patient], serviceName: String, shift: String) {
        isGenerating = true
        errorMessage = nil

        let transferData = patients.map { patient in
            PatientTransferData(
                id: patient.id.uuidString,
                name: patient.name,
                mrn: patient.mrn,
                room: patient.room,
                surgeon: patient.surgeon,
                diagnosis: patient.diagnosis,
                procedure: patient.procedure,
                surgeryDate: patient.surgeryDate?.isoString ?? "",
                codeStatus: patient.codeStatusRaw,
                allergies: patient.allergies,
                priority: patient.priorityRaw,
                notes: patient.notes,
                tasks: patient.tasks.sorted { $0.sortOrder < $1.sortOrder }.map { task in
                    PatientTransferData.TaskTransferData(
                        id: task.id.uuidString,
                        text: task.text,
                        isDone: task.isDone
                    )
                }
            )
        }

        let payload = TransferPayload.build(
            patients: transferData,
            serviceName: serviceName,
            shift: shift
        )

        do {
            let encoded = try CompressionService.encode(payload)
            payloadSize = encoded.utf8.count
            let capacity = QRCodeService.estimateQRCapacity(encoded)
            isOverQRLimit = capacity.isOverLimit

            if !isOverQRLimit {
                let correctionLevel = QRCodeService.suggestedCorrectionLevel(for: encoded)
                qrImage = QRCodeService.generateQRCode(
                    from: encoded,
                    size: 600,
                    correctionLevel: correctionLevel
                )
            } else {
                // Still generate at lowest EC for display, but warn user
                qrImage = QRCodeService.generateQRCode(
                    from: encoded,
                    size: 600,
                    correctionLevel: "L"
                )
            }
            isGenerating = false
        } catch {
            errorMessage = error.localizedDescription
            isGenerating = false
        }
    }

    /// Returns the raw transfer data for peer-to-peer transfer.
    func getTransferData(patients: [Patient], serviceName: String, shift: String) -> Data? {
        let transferData = patients.map { patient in
            PatientTransferData(
                id: patient.id.uuidString,
                name: patient.name,
                mrn: patient.mrn,
                room: patient.room,
                surgeon: patient.surgeon,
                diagnosis: patient.diagnosis,
                procedure: patient.procedure,
                surgeryDate: patient.surgeryDate?.isoString ?? "",
                codeStatus: patient.codeStatusRaw,
                allergies: patient.allergies,
                priority: patient.priorityRaw,
                notes: patient.notes,
                tasks: patient.tasks.sorted { $0.sortOrder < $1.sortOrder }.map { task in
                    PatientTransferData.TaskTransferData(
                        id: task.id.uuidString,
                        text: task.text,
                        isDone: task.isDone
                    )
                }
            )
        }

        let payload = TransferPayload.build(
            patients: transferData,
            serviceName: serviceName,
            shift: shift
        )

        return try? payload.jsonData()
    }
}
