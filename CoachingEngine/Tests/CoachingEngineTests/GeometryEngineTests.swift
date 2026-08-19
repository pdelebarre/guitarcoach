import XCTest
@testable import CoachingEngine

final class GeometryEngineTests: XCTestCase {
    var engine: GeometryEngine!
    var reference: NeckReference!

    override func setUp() {
        engine = GeometryEngine()
        // 4 visible fret spaces; tolerance relative to one fret height.
        reference = NeckReference(visibleFrets: 4, fretTolerance: 0.35, minConfidence: 0.6)
    }

    /// Fret centers for visibleFrets=4: fret1 at y=0.125, fret2 at 0.375, etc.
    private func fretCenterY(_ fret: Int) -> Double {
        reference.fretCenterY(for: fret)
    }

    /// x for a given string (1...6) on a 6-string grid.
    private func x(forString s: GuitarString) -> Double {
        (Double(s) - 0.5) / 6.0
    }

    func testPerfectFormProducesNoCues() {
        let obs = HandObservation(fingertips: [
            .init(finger: .index, x: x(forString: 2), y: fretCenterY(1), confidence: 0.9),
            .init(finger: .middle, x: x(forString: 4), y: fretCenterY(2), confidence: 0.9),
            .init(finger: .ring, x: x(forString: 5), y: fretCenterY(3), confidence: 0.9)
        ])
        let result = engine.assess(observation: obs, target: StarterChords.cMajor, reference: reference)
        XCTAssertTrue(result.cues.isEmpty, "Perfect form should produce no cues, got \(result.cues)")
    }

    func testWrongStringIsDetected() {
        // Index on string 4 instead of string 2.
        let obs = HandObservation(fingertips: [
            .init(finger: .index, x: x(forString: 4), y: fretCenterY(1), confidence: 0.9)
        ])
        let result = engine.assess(observation: obs, target: StarterChords.cMajor, reference: reference)
        XCTAssertTrue(result.cues.contains {
            if case .wrongString(finger: .index, expectedString: 2, actualString: 4) = $0 { return true }
            return false
        })
    }

    func testWrongFretIsDetected() {
        // Index on fret 3 instead of fret 1.
        let obs = HandObservation(fingertips: [
            .init(finger: .index, x: x(forString: 2), y: fretCenterY(3), confidence: 0.9)
        ])
        let result = engine.assess(observation: obs, target: StarterChords.cMajor, reference: reference)
        XCTAssertTrue(result.cues.contains {
            if case .wrongFret(finger: .index, expectedFret: 1, actualFret: 3) = $0 { return true }
            return false
        })
    }

    func testMissingFingerIsDetected() {
        let obs = HandObservation(fingertips: [
            .init(finger: .index, x: x(forString: 2), y: fretCenterY(1), confidence: 0.9)
            // middle and ring absent
        ])
        let result = engine.assess(observation: obs, target: StarterChords.cMajor, reference: reference)
        XCTAssertTrue(result.cues.contains { if case .missingFinger = $0 { return true } else { return false } })
    }

    func testLowConfidenceGatesAllCorrections() {
        // Index has low confidence but correct placement; must still gate.
        let obs = HandObservation(fingertips: [
            .init(finger: .index, x: x(forString: 2), y: fretCenterY(1), confidence: 0.3)
        ])
        let result = engine.assess(observation: obs, target: StarterChords.cMajor, reference: reference)
        XCTAssertEqual(result.cues, [.lowConfidence(reason: "hand_or_occlusion")],
                       "Low confidence must emit repositioning cue, not a correction")
    }

    func testExcessiveHandRotationSurfaces() {
        let obs = HandObservation(fingertips: [
            .init(finger: .index, x: x(forString: 2), y: fretCenterY(1), confidence: 0.9)
        ])
        let result = engine.assess(observation: obs, target: StarterChords.cMajor,
                                   reference: reference, handRotationDegrees: 45)
        XCTAssertTrue(result.cues.contains { if case .excessiveHandRotation = $0 { return true } else { return false } })
    }

    func testFeedbackIsRankedAndCapped() {
        // Produce many cues; ensure ranking (lowConfidence last-wins? no, severity) and cap at 3.
        let obs = HandObservation(fingertips: []) // nothing detected -> all missing fingers
        let result = engine.assess(observation: obs, target: StarterChords.cMajor, reference: reference)
        XCTAssertEqual(result.cues.count, 3, "Feedback must be capped at 3 items, got \(result.cues)")
        // missingFinger severity (4) is highest among present cues.
        XCTAssertTrue(result.cues.allSatisfy { if case .missingFinger = $0 { return true } else { return false } })
    }
}
