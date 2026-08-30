import AVFoundation
import Foundation
import Observation
import UIKit

/// Owns the AVFoundation capture session lifecycle for the prototype. Emits
/// downscaled sample buffers in real time; raw frames are processed in memory
/// and never stored.
///
/// Uses the front camera with mirrored output so raw buffers match the preview.
/// Automatically adjusts orientation when the device rotates.
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
    private(set) var currentOrientation: AVCaptureVideoOrientation = .portrait
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.pdelebarre.guitarcoach.capture")
    private var onSampleBuffer: ((CMSampleBuffer) -> Void)?
    private var isConfigured = false
    private var videoOutputConnection: AVCaptureConnection?
    private var orientationObserver: NSObjectProtocol?

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
        startOrientationObservation()
    }

    func stop() {
        stopOrientationObservation()
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    private func configure() {
        guard !isConfigured else { return }
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
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

        // Mirror the output for front camera so raw buffers match the preview.
        if let connection = output.connection(with: .video) {
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
            connection.videoOrientation = currentOrientation
            videoOutputConnection = connection
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

    // MARK: - Orientation

    /// Converts device orientation to the front-mirrored video orientation.
    /// Mirrored output already compensates for the front camera, so the
    /// standard (back-camera) mapping is correct here.
    private static func videoOrientation(from deviceOrientation: UIDeviceOrientation) -> AVCaptureVideoOrientation? {
        switch deviceOrientation {
        case .portrait: .portrait
        case .portraitUpsideDown: .portraitUpsideDown
        case .landscapeLeft: .landscapeLeft
        case .landscapeRight: .landscapeRight
        default: nil // faceUp, faceDown, unknown — keep current value
        }
    }

    private func startOrientationObservation() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        orientationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onOrientationChange()
        }
        // Capture initial orientation
        onOrientationChange()
    }

    private func stopOrientationObservation() {
        if let observer = orientationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        orientationObserver = nil
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    private func onOrientationChange() {
        guard let newOrientation = Self.videoOrientation(from: UIDevice.current.orientation) else { return }
        currentOrientation = newOrientation
        sessionQueue.async { [weak self] in
            self?.videoOutputConnection?.videoOrientation = newOrientation
        }
    }
}
