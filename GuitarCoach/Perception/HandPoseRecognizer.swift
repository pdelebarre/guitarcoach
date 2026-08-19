import CoreImage
import Foundation
import Vision
import CoachingEngine

/// Runs Vision hand-pose detection on a frame and converts image-space
/// fingertip landmarks into neck-relative normalized coordinates, using a
/// neck/fretboard region detected in the same frame as the reference geometry.
struct HandPoseRecognizer {
    struct Detection {
        var observation: HandObservation
        var handRotationDegrees: Double?
        var neckConfidence: Double?
        var detected: Bool
    }

    private let neckReference: NeckReference
    private let neckDetector = NeckDetector()

    init(neckReference: NeckReference = NeckReference(visibleFrets: 4, fretTolerance: 0.35, minConfidence: 0.6)) {
        self.neckReference = neckReference
    }

    /// Processes a pixel buffer and returns the hand observation plus an
    /// estimated rotation, or `nil` when no hand is found. When no credible neck
    /// region is detected, `detected` is false so the caller can ask for
    /// repositioning rather than emit a potentially-wrong correction.
    func detect(in pixelBuffer: CVPixelBuffer) -> Detection? {
        // Establish reference geometry first: without a neck, coordinates are meaningless.
        guard let neck = neckDetector.detect(in: pixelBuffer) else {
            return Detection(observation: HandObservation(fingertips: []),
                             handRotationDegrees: nil,
                             neckConfidence: nil,
                             detected: false)
        }

        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        do {
            try handler.perform([request])
        } catch {
            return Detection(observation: HandObservation(fingertips: []),
                             handRotationDegrees: nil,
                             neckConfidence: neck.confidence,
                             detected: false)
        }

        guard let observation = request.results?.first else {
            return Detection(observation: HandObservation(fingertips: []),
                             handRotationDegrees: nil,
                             neckConfidence: neck.confidence,
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
                let neckPoint = neck.quadrilateral.project(point.location)
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
                         neckConfidence: neck.confidence,
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
