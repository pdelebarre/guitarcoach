import CoreImage
import Foundation
import Vision
import CoachingEngine

/// Runs Vision hand-pose detection on a frame and converts image-space
/// fingertip landmarks into neck-relative normalized coordinates.
///
/// For the M0 prototype the neck is approximated by a normalized crop of the
/// frame (a centered band). Real neck-alignment geometry is a later milestone;
/// this placeholder is the seam that must be validated with learners (see issue
/// #8) and replaced by the reference-geometry pipeline.
struct HandPoseRecognizer {
    struct Detection {
        var observation: HandObservation
        var handRotationDegrees: Double?
        var detected: Bool
    }

    private let neckReference: NeckReference
    private let imageToNeck: ImageToNeckMapper

    init(neckReference: NeckReference = NeckReference(visibleFrets: 4),
         imageToNeck: ImageToNeckMapper = .defaultPortrait) {
        self.neckReference = neckReference
        self.imageToNeck = imageToNeck
    }

    /// Processes a pixel buffer and returns the hand observation plus an
    /// estimated rotation, or `nil` when no hand is found.
    ///
    /// - Parameter orientation: The EXIF orientation matching the current
    ///   device orientation. The caller (PracticeViewModel) is responsible
    ///   for mapping from device rotation.
    func detect(in pixelBuffer: CVPixelBuffer,
                orientation: CGImagePropertyOrientation = .up) -> Detection? {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                             orientation: orientation)
        do {
            try handler.perform([request])
        } catch {
            return Detection(observation: HandObservation(fingertips: []),
                             handRotationDegrees: nil,
                             detected: false)
        }

        guard let observation = request.results?.first else {
            return Detection(observation: HandObservation(fingertips: []),
                             handRotationDegrees: nil,
                             detected: false)
        }

        let fingerMap: [(Finger, VNHumanHandPoseObservation.JointName)] = [
            (.index, .indexTip),
            (.middle, .middleTip),
            (.ring, .ringTip),
            (.pinky, .littleTip)
        ]

        var fingertips: [ObservedFingertip] = []
        do {
            for (finger, joint) in fingerMap {
                let point = try observation.recognizedPoint(joint)
                guard point.confidence > 0.3 else { continue }
                let neckPoint = imageToNeck.map(point.location)
                fingertips.append(ObservedFingertip(
                    finger: finger,
                    x: neckPoint.x,
                    y: neckPoint.y,
                    confidence: Double(point.confidence)
                ))
            }
        } catch {
            // fall through with whatever we captured
        }

        return Detection(observation: HandObservation(fingertips: fingertips),
                         handRotationDegrees: estimateRotation(from: observation),
                         detected: true)
    }

    private func estimateRotation(from observation: VNHumanHandPoseObservation) -> Double? {
        // Rough rotation from index MCP to wrist; a coarse stand-in until the
        // neck-alignment model lands. Returns degrees.
        guard let indexMCP = try? observation.recognizedPoint(.indexMCP),
              let wrist = try? observation.recognizedPoint(.wrist),
              indexMCP.confidence > 0.3, wrist.confidence > 0.3 else {
            return nil
        }
        let dx = indexMCP.location.x - wrist.location.x
        let dy = indexMCP.location.y - wrist.location.y
        return Double(atan2(dy, dx)) * 180.0 / .pi
    }
}

/// Maps Vision normalized image coordinates (origin bottom-left) into
/// neck-relative normalized coordinates for the prototype's centered-band crop.
struct ImageToNeckMapper {
    /// The normalized (0...1) band of the frame assumed to contain the neck:
    /// (xMin, xMax, yMin, yMax) in image coordinates.
    let crop: CGRect

    static let defaultPortrait = ImageToNeckMapper(crop: CGRect(x: 0.05, y: 0.1, width: 0.9, height: 0.5))

    func map(_ point: CGPoint) -> CGPoint {
        let nx = (point.x - crop.minX) / crop.width
        let ny = (point.y - crop.minY) / crop.height
        return CGPoint(x: min(max(nx, 0), 1), y: min(max(ny, 0), 1))
    }
}
