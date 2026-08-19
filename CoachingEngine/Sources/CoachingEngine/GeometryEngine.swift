import Foundation

/// Translates observed hand landmarks into coaching cues by comparing them with
/// the target chord shape in neck space. Pure and deterministic so it can be
/// unit-tested against recorded fixtures.
public struct GeometryEngine: Sendable {
    public init() {}

    /// Assesses a single hand observation against a target chord. Returns a
    /// ranked `Feedback`. When confidence is below threshold, returns a
    /// low-confidence repositioning cue instead of any correction.
    public func assess(
        observation: HandObservation,
        target: ChordShape,
        reference: NeckReference,
        handRotationDegrees: Double? = nil
    ) -> Feedback {
        // Confidence gating: if any observed fingertip is too uncertain, refuse
        // to emit a correction and ask for repositioning.
        if observation.fingertips.contains(where: { $0.confidence < reference.minConfidence }) {
            return Feedback(cues: [.lowConfidence(reason: "hand_or_occlusion")])
        }

        var cues: [FeedbackCue] = []

        // Excessive hand rotation is a setup-level problem worth surfacing early.
        if let rotation = handRotationDegrees, abs(rotation) > 30 {
            cues.append(.excessiveHandRotation(degrees: rotation))
        }

        for targetFinger in target.targets {
            guard let fingertip = observation.fingertip(for: targetFinger.finger) else {
                cues.append(.missingFinger(finger: targetFinger.finger))
                continue
            }

            let actualString = reference.string(for: fingertip.x)
            let actualFret = reference.fret(for: fingertip.y)

            if actualString != targetFinger.string {
                cues.append(.wrongString(finger: targetFinger.finger,
                                         expectedString: targetFinger.string,
                                         actualString: actualString))
            }
            if actualFret != targetFinger.fret {
                // Distinguish "clearly on a different fret" from "too far from the target fret".
                if reference.isOnFret(fingertip.y, targetFret: targetFinger.fret) {
                    cues.append(.fingerTooFarFromFret(finger: targetFinger.finger))
                } else {
                    cues.append(.wrongFret(finger: targetFinger.finger,
                                           expectedFret: targetFinger.fret,
                                           actualFret: actualFret))
                }
            }
        }

        return Feedback(cues: cues)
    }
}
