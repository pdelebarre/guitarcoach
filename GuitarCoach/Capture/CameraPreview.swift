import AVFoundation
import SwiftUI

/// A `UIViewRepresentable` that renders the camera preview.
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
    }
}
