import Foundation

/// The bounded, explainable coaching cues the MVP is allowed to emit.
/// These are evidence objects, never UI strings; the UI renders them.
public enum FeedbackCue: Equatable, Sendable {
    case wrongFret(finger: Finger, expectedFret: Int, actualFret: Int)
    case wrongString(finger: Finger, expectedString: GuitarString, actualString: GuitarString)
    case fingerTooFarFromFret(finger: Finger)
    case missingFinger(finger: Finger)
    case excessiveHandRotation(degrees: Double)
    /// Low confidence / occlusion: ask for repositioning, never a correction.
    case lowConfidence(reason: String)

    /// Pedagogical severity used to rank feedback. Higher = more important.
    var severity: Int {
        switch self {
        case .lowConfidence: return 5
        case .missingFinger: return 4
        case .excessiveHandRotation: return 3
        case .wrongFret: return 2
        case .wrongString: return 1
        case .fingerTooFarFromFret: return 0
        }
    }
}

/// A ranked list of coaching cues, never more than `maxItems`, sorted by severity.
public struct Feedback: Equatable, Sendable {
    public let cues: [FeedbackCue]

    public init(cues: [FeedbackCue], maxItems: Int = 3) {
        self.cues = Array(cues.sorted { $0.severity > $1.severity }.prefix(maxItems))
    }
}
