import Foundation

/// Defines the reference geometry of the visible fretboard region so that
/// normalized neck coordinates can be converted into string/fret cells with
/// uncertainty. This is the deterministic core that gets unit-tested against
/// recorded fixtures.
public struct NeckReference: Sendable {
    /// Number of fret spaces visible in the mapped region (1 = nut-to-first fret).
    public let visibleFrets: Int
    /// How far a fingertip can be (in the same normalized-y units) from the
    /// target fret center and still be considered "on the fret". Values are
    /// normalized to the visible fret height.
    public let fretTolerance: Double
    /// Confidence below which we refuse to emit a correction (see gating).
    public let minConfidence: Double

    public init(visibleFrets: Int, fretTolerance: Double = 0.35, minConfidence: Double = 0.6) {
        self.visibleFrets = visibleFrets
        self.fretTolerance = fretTolerance
        self.minConfidence = minConfidence
    }

    /// Converts normalized `y` (0 at nut) into a nearest fret number in 1...visibleFrets.
    public func fret(for y: Double) -> Int {
        let clamped = min(max(y, 0), 0.999)
        let fret = Int(floor(clamped * Double(visibleFrets))) + 1
        return min(max(fret, 1), visibleFrets)
    }

    /// Converts normalized `x` (0 near 1st string) into a nearest string in 1...6.
    public func string(for x: Double) -> GuitarString {
        let clamped = min(max(x, 0), 0.999)
        let string = Int(floor(clamped * 6)) + 1
        return min(max(string, 1), 6)
    }

    /// Normalized-y distance of a point from the target fret's center.
    /// Fret centers sit at the midpoint of each fret space.
    public func fretCenterY(for fret: Int) -> Double {
        let fret = min(max(fret, 1), visibleFrets)
        return (Double(fret) - 0.5) / Double(visibleFrets)
    }

    /// True when the fingertip is close enough to the target fret center.
    public func isOnFret(_ y: Double, targetFret: Int) -> Bool {
        abs(y - fretCenterY(for: targetFret)) <= fretTolerance * (1.0 / Double(visibleFrets))
    }
}
