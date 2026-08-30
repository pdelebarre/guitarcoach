import AVFoundation
import SwiftUI
import UIKit

/// A `UIViewRepresentable` that renders the camera preview and automatically
/// rotates to match device orientation.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        view.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.session = session
    }

    final class PreviewView: UIView {
        var session: AVCaptureSession? {
            get { (layer as! AVCaptureVideoPreviewLayer).session }
            set { (layer as! AVCaptureVideoPreviewLayer).session = newValue }
        }

        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        private var orientationObserver: NSObjectProtocol?

        override func didMoveToWindow() {
            super.didMoveToWindow()

            if window != nil {
                startOrientationObservation()
            } else {
                stopOrientationObservation()
            }
        }

        private func startOrientationObservation() {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            orientationObserver = NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.updateOrientation()
            }
            updateOrientation()
        }

        private func stopOrientationObservation() {
            if let observer = orientationObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            orientationObserver = nil
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }

        private func updateOrientation() {
            guard let connection = (layer as? AVCaptureVideoPreviewLayer)?.connection,
                  connection.isVideoOrientationSupported
            else { return }

            switch UIDevice.current.orientation {
            case .portrait:
                connection.videoOrientation = .portrait
            case .portraitUpsideDown:
                connection.videoOrientation = .portraitUpsideDown
            case .landscapeLeft:
                connection.videoOrientation = .landscapeRight
            case .landscapeRight:
                connection.videoOrientation = .landscapeLeft
            default:
                break
            }
        }
    }
}