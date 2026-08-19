import AVFoundation
import Foundation
import Observation

/// Owns the AVFoundation capture session lifecycle for the prototype. Emits
/// downscaled sample buffers in real time; raw frames are processed in memory
/// and never stored.
@MainActor
@Observable
final class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    enum State: Equatable, Sendable {
        case idle
        case permissionDenied
        case running
        case failed(String)
    }

    private(set) var state: State = .idle
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.pdelebarre.guitarcoach.capture")
    private var onSampleBuffer: ((CMSampleBuffer) -> Void)?
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

    private func configure() {
        guard !isConfigured else { return }
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
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

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        output.setSampleBufferDelegate(self, queue: sessionQueue)
        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        isConfigured = true
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
