import AVFoundation
import Foundation
import Observation

/// Owns the AVFoundation capture session lifecycle for the prototype. Emits
/// downscaled sample buffers in real time; raw frames are processed in memory
/// and never stored. Supports switching between the front and rear cameras at
/// runtime.
@MainActor
@Observable
final class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    enum State: Equatable, Sendable {
        case idle
        case permissionDenied
        case running
        case failed(String)
    }

    enum Position: Sendable {
        case front
        case back

        var avPosition: AVCaptureDevice.Position {
            switch self {
            case .front: return .front
            case .back: return .back
            }
        }
    }

    private(set) var state: State = .idle
    /// The active camera. Front is the default.
    private(set) var position: Position = .front
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.pdelebarre.guitarcoach.capture")
    private var onSampleBuffer: ((CMSampleBuffer) -> Void)?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var isConfigured = false

    override init() {
        super.init()
    }

    func requestAccess() async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        if granted {
            sessionQueue.async { [weak self] in
                self?.configure()
            }
        } else {
            state = .permissionDenied
        }
    }

    /// Starts the session and delivers sample buffers to `onSampleBuffer`.
    func start(onSampleBuffer: @escaping (CMSampleBuffer) -> Void) async {
        self.onSampleBuffer = onSampleBuffer
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.configure()
            self.session.startRunning()
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    /// Switches to the opposite camera while the session is running.
    func toggleCamera() {
        let next: Position = position == .front ? .back : .front
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.configure(position: next)
        }
    }

    /// Builds the input for the current position if none exists, or swaps the
    /// active input when the position changes. Safe to call from the session
    /// queue, including while the session is running.
    private func configure(position requested: Position? = nil) {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        if !isConfigured {
            session.sessionPreset = .high
        }

        let active: Position = requested ?? position
        position = active

        // Remove any existing camera input so switching positions works at runtime.
        let existingInputs = session.inputs.compactMap { $0 as? AVCaptureDeviceInput }
        for input in existingInputs {
            session.removeInput(input)
        }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: active.avPosition) else {
            setState(.failed("no_camera"))
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            setState(.failed("input_error"))
            return
        }

        if !isConfigured {
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            output.setSampleBufferDelegate(self, queue: sessionQueue)
            if session.canAddOutput(output) {
                session.addOutput(output)
                videoOutput = output
            }
            isConfigured = true
        }
    }

    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        Task { @MainActor [weak self] in
            self?.onSampleBuffer?(sampleBuffer)
        }
    }

    /// Updates `state`, hopping onto the main actor. Safe to call from the
    /// background capture queue.
    private nonisolated func setState(_ newState: State) {
        Task { @MainActor [weak self] in
            self?.state = newState
        }
    }
}
