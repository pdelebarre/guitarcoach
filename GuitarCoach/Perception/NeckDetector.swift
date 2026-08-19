import Foundation
import Vision
import CoachingEngine

/// Detects the guitar neck/fretboard region in a frame using Vision rectangle
/// detection, and provides a `NeckQuadrilateral` used as the reference geometry
/// for string/fret mapping. This replaces the fixed-crop placeholder so the
/// string/fret grid tracks where the neck actually is in the frame.
///
/// Selection heuristic: among detected rectangles, prefer long, thin, large ones
/// (a fretboard is a high-aspect-ratio region). Because this is heuristic, the
/// detector gates on confidence and returns `nil` when no credible neck is found,
/// so the coaching layer can ask for repositioning instead of emitting a
/// confidently-wrong correction.
struct NeckDetector {
    struct Result {
        var quadrilateral: NeckQuadrilateral
        var confidence: Double
    }

    /// Minimum aspect ratio (long/short edge) to consider a rectangle a neck.
    var minAspectRatio: CGFloat = 1.8
    /// Minimum Vision observation confidence (0...1).
    var minConfidence: Float = 0.4

    /// Returns the most likely neck quadrilateral in the frame, or `nil`.
    func detect(in pixelBuffer: CVPixelBuffer) -> Result? {
        let request = VNDetectRectanglesRequest()
        request.minimumConfidence = minConfidence
        request.minimumAspectRatio = minAspectRatio
        request.maximumObservations = 10

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        guard let observations = request.results, !observations.isEmpty else { return nil }

        // Pick the largest-area rectangle that still looks like a neck.
        let candidates = observations.map { observation -> (VNRectangleObservation, Double) in
            let quad = NeckQuadrilateral(
                topLeft: observation.topLeft,
                topRight: observation.topRight,
                bottomLeft: observation.bottomLeft,
                bottomRight: observation.bottomRight
            )
            return (observation, quad.area)
        }

        guard let best = candidates.max(by: { $0.1 < $1.1 }) else { return nil }
        let observation = best.0
        let quad = NeckQuadrilateral(
            topLeft: observation.topLeft,
            topRight: observation.topRight,
            bottomLeft: observation.bottomLeft,
            bottomRight: observation.bottomRight
        )
        return Result(quadrilateral: quad, confidence: Double(observation.confidence))
    }
}
