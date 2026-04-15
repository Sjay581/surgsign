import AVFoundation
import SwiftUI
import SwiftData

/// Full-screen camera scanner for incoming shift handoff QR codes.
///
/// Uses AVCaptureSession with metadata output to detect and decode QR codes.
/// On successful decode, presents a `ScanPreviewView` for the user to confirm import.
struct ScanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var scanViewModel = ScanViewModel()

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            cameraLayer
            scanOverlay
            topControls
            instructionLabel

            if let payload = scanViewModel.scannedPayload {
                Color.black.opacity(0.001) // catch taps
                    .ignoresSafeArea()
                    .sheet(isPresented: .constant(true)) {
                        scanViewModel.reset()
                    } content: {
                        ScanPreviewView(payload: payload) {
                            scanViewModel.importPatients(
                                from: payload,
                                context: modelContext,
                                appState: appState
                            )
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                dismiss()
                            }
                        }
                    }
            }
        }
        .statusBarHidden()
        .onAppear {
            scanViewModel.checkCameraPermission()
        }
    }

    // MARK: - Camera Layer

    @ViewBuilder
    private var cameraLayer: some View {
        switch scanViewModel.cameraPermissionStatus {
        case .authorized:
            QRScannerRepresentable(onCodeScanned: { code in
                scanViewModel.processQRCode(code)
            })
            .ignoresSafeArea()

        case .denied, .restricted:
            permissionDeniedView

        case .notDetermined:
            VStack(spacing: 16) {
                ProgressView()
                    .tint(Color.surgAccent)
                Text("Requesting camera access...")
                    .font(.subheadline)
                    .foregroundStyle(Color.surgTextSecondary)
            }
            .onAppear {
                scanViewModel.requestCameraPermission()
            }

        @unknown default:
            permissionDeniedView
        }
    }

    // MARK: - Scan Overlay

    private var scanOverlay: some View {
        GeometryReader { geometry in
            let scanSize: CGFloat = min(geometry.size.width * 0.7, 300)
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2 - 40

            // Semi-transparent background with clear center
            Canvas { context, size in
                // Full overlay
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(Color.black.opacity(0.55))
                )

                // Cut out the scanning rectangle
                let scanRect = CGRect(
                    x: centerX - scanSize / 2,
                    y: centerY - scanSize / 2,
                    width: scanSize,
                    height: scanSize
                )
                context.blendMode = .clear
                context.fill(
                    Path(roundedRect: scanRect, cornerRadius: 16),
                    with: .color(.white)
                )
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Corner brackets
            scanCornerBrackets(
                centerX: centerX,
                centerY: centerY,
                size: scanSize
            )
            .allowsHitTesting(false)
        }
        .opacity(scanViewModel.cameraPermissionStatus == .authorized ? 1 : 0)
    }

    private func scanCornerBrackets(centerX: CGFloat, centerY: CGFloat, size: CGFloat) -> some View {
        let bracketLength: CGFloat = 30
        let lineWidth: CGFloat = 3
        let left = centerX - size / 2
        let top = centerY - size / 2
        let right = centerX + size / 2
        let bottom = centerY + size / 2

        return ZStack {
            // Top-left
            Path { path in
                path.move(to: CGPoint(x: left, y: top + bracketLength))
                path.addLine(to: CGPoint(x: left, y: top + 8))
                path.addQuadCurve(to: CGPoint(x: left + 8, y: top),
                                  control: CGPoint(x: left, y: top))
                path.addLine(to: CGPoint(x: left + bracketLength, y: top))
            }
            .stroke(Color.surgAccent, lineWidth: lineWidth)

            // Top-right
            Path { path in
                path.move(to: CGPoint(x: right - bracketLength, y: top))
                path.addLine(to: CGPoint(x: right - 8, y: top))
                path.addQuadCurve(to: CGPoint(x: right, y: top + 8),
                                  control: CGPoint(x: right, y: top))
                path.addLine(to: CGPoint(x: right, y: top + bracketLength))
            }
            .stroke(Color.surgAccent, lineWidth: lineWidth)

            // Bottom-left
            Path { path in
                path.move(to: CGPoint(x: left, y: bottom - bracketLength))
                path.addLine(to: CGPoint(x: left, y: bottom - 8))
                path.addQuadCurve(to: CGPoint(x: left + 8, y: bottom),
                                  control: CGPoint(x: left, y: bottom))
                path.addLine(to: CGPoint(x: left + bracketLength, y: bottom))
            }
            .stroke(Color.surgAccent, lineWidth: lineWidth)

            // Bottom-right
            Path { path in
                path.move(to: CGPoint(x: right - bracketLength, y: bottom))
                path.addLine(to: CGPoint(x: right - 8, y: bottom))
                path.addQuadCurve(to: CGPoint(x: right, y: bottom - 8),
                                  control: CGPoint(x: right, y: bottom))
                path.addLine(to: CGPoint(x: right, y: bottom - bracketLength))
            }
            .stroke(Color.surgAccent, lineWidth: lineWidth)
        }
    }

    // MARK: - Top Controls

    private var topControls: some View {
        VStack {
            HStack {
                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(.trailing, 20)
                .padding(.top, 12)
            }

            Spacer()
        }
    }

    // MARK: - Instruction Label

    private var instructionLabel: some View {
        VStack {
            Spacer()

            VStack(spacing: 8) {
                Text("Scan Handoff QR")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("Point camera at the outgoing resident's QR code")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                if let error = scanViewModel.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                        Text(error)
                            .font(.caption)
                    }
                    .foregroundStyle(Color.surgRed)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.surgRed.opacity(0.15), in: Capsule())
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 80)
        }
    }

    // MARK: - Permission Denied

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.surgTextSecondary)

            Text("Camera Access Required")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.surgText)

            Text("SurgSign needs camera access to scan handoff QR codes. Please enable it in Settings.")
                .font(.subheadline)
                .foregroundStyle(Color.surgTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.surgAccent, in: Capsule())
            }
        }
    }
}

// MARK: - ScanViewModel

/// View model managing QR scan state, payload decoding, and patient import.
@Observable
final class ScanViewModel {
    var isScanning: Bool = false
    var scannedPayload: TransferPayload?
    var errorMessage: String?
    var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined

    /// Checks the current camera authorization status.
    func checkCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    /// Requests camera permission from the user.
    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.cameraPermissionStatus = granted ? .authorized : .denied
            }
        }
    }

    /// Processes a raw QR code string, attempting to decode it as a SurgSign transfer payload.
    func processQRCode(_ rawString: String) {
        guard scannedPayload == nil else { return } // prevent double-processing

        do {
            let payload = try CompressionService.decode(rawString)
            scannedPayload = payload
            errorMessage = nil
        } catch {
            errorMessage = "Invalid QR code format. Not a SurgSign handoff."
        }
    }

    /// Imports patients from a decoded transfer payload into the SwiftData store.
    func importPatients(from payload: TransferPayload, context: ModelContext, appState: AppState) {
        // Update service name from the incoming payload
        appState.serviceName = payload.svc

        let isoFormatter = DateFormatter.isoDate

        for dto in payload.pts {
            let surgeryDate: Date? = dto.sd.isEmpty ? nil : isoFormatter.date(from: dto.sd)

            let tasks = dto.issues.enumerated().map { index, taskDTO in
                PatientTask(
                    text: taskDTO.t,
                    isDone: taskDTO.d == 1,
                    sortOrder: index
                )
            }

            let patient = Patient(
                name: dto.n,
                mrn: dto.m,
                room: dto.r,
                surgeon: dto.s,
                diagnosis: dto.dx,
                procedure: dto.px,
                surgeryDate: surgeryDate,
                codeStatus: CodeStatus(rawValue: dto.cs) ?? .fullCode,
                allergies: dto.al,
                priority: Priority(rawValue: dto.pr) ?? .stable,
                notes: dto.nt,
                sortOrder: 0,
                tasks: tasks
            )

            context.insert(patient)
        }

        try? context.save()
    }

    /// Resets the scan state for a new scan attempt.
    func reset() {
        scannedPayload = nil
        errorMessage = nil
        isScanning = false
    }
}

// MARK: - QR Scanner UIViewControllerRepresentable

/// SwiftUI bridge wrapping a `QRScannerViewController` for camera-based QR detection.
struct QRScannerRepresentable: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {
        // No dynamic updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }

    final class Coordinator: NSObject, QRScannerViewControllerDelegate {
        let onCodeScanned: (String) -> Void
        private var hasScanned = false

        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }

        func qrScannerDidScan(_ code: String) {
            guard !hasScanned else { return }
            hasScanned = true
            DispatchQueue.main.async { [weak self] in
                self?.onCodeScanned(code)
            }
        }
    }
}

// MARK: - QRScannerViewControllerDelegate

protocol QRScannerViewControllerDelegate: AnyObject {
    func qrScannerDidScan(_ code: String)
}

// MARK: - QRScannerViewController

/// UIKit view controller that configures an AVCaptureSession for QR code scanning.
///
/// Sets up the back camera with metadata output filtered to `.qr` type.
/// Runs the capture session on a dedicated background serial queue.
final class QRScannerViewController: UIViewController {
    weak var delegate: QRScannerViewControllerDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let sessionQueue = DispatchQueue(label: "com.surgsign.scannerSession")
    private var hasDetectedCode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        #if targetEnvironment(simulator)
        showSimulatorMessage()
        #else
        setupCaptureSession()
        #endif
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    // MARK: - Session Setup

    private func setupCaptureSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .high

        // Configure video input from the back camera
        guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            showNoCameraMessage()
            return
        }

        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            showNoCameraMessage()
            return
        }

        guard session.canAddInput(videoInput) else {
            showNoCameraMessage()
            return
        }
        session.addInput(videoInput)

        // Configure metadata output for QR code detection
        let metadataOutput = AVCaptureMetadataOutput()
        guard session.canAddOutput(metadataOutput) else {
            showNoCameraMessage()
            return
        }
        session.addOutput(metadataOutput)

        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]

        // Set up the preview layer
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview

        captureSession = session
    }

    // MARK: - Session Lifecycle

    private func startSession() {
        guard let session = captureSession, !session.isRunning else { return }
        sessionQueue.async { [weak session] in
            session?.startRunning()
        }
    }

    private func stopSession() {
        guard let session = captureSession, session.isRunning else { return }
        sessionQueue.async { [weak session] in
            session?.stopRunning()
        }
    }

    // MARK: - Fallback Views

    private func showSimulatorMessage() {
        let label = UILabel()
        label.text = "Camera is not available\nin the Simulator.\n\nUse a physical device to scan QR codes."
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
        ])
    }

    private func showNoCameraMessage() {
        let label = UILabel()
        label.text = "No camera available.\nPlease check your device."
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
        ])
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !hasDetectedCode else { return }

        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              readableObject.type == .qr,
              let stringValue = readableObject.stringValue else {
            return
        }

        // Stop the session immediately to prevent duplicate scans
        hasDetectedCode = true
        stopSession()

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        delegate?.qrScannerDidScan(stringValue)
    }
}
