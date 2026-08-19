import Foundation

/// A fretting-hand finger used to press a string.
public enum Finger: Int, Codable, CaseIterable, Sendable {
    case index = 1
    case middle = 2
    case ring = 3
    case pinky = 4

    public var displayName: String {
        switch self {
        case .index: return "index"
        case .middle: return "middle"
        case .ring: return "ring"
        case .pinky: return "pinky"
        }
    }
}

/// String numbering: 1 = high E (thinnest), 6 = low E (thickest).
public typealias GuitarString = Int

/// The expected fretting-hand shape for a chord. This is domain data only; it
/// never contains UI strings. Hints are plain-language coaching cues surfaced by
/// the UI layer.
public struct ChordShape: Codable, Equatable, Sendable {
    public struct FingerTarget: Codable, Equatable, Sendable {
        public let finger: Finger
        public let string: GuitarString
        public let fret: Int

        public init(finger: Finger, string: GuitarString, fret: Int) {
            self.finger = finger
            self.string = string
            self.fret = fret
        }
    }

    public let name: String
    public let targets: [FingerTarget]
    public let hints: [String]

    public init(name: String, targets: [FingerTarget], hints: [String]) {
        self.name = name
        self.targets = targets
        self.hints = hints
    }

    /// Returns the expected target for a given finger, if the chord uses it.
    public func target(for finger: Finger) -> FingerTarget? {
        targets.first { $0.finger == finger }
    }

    /// Highest fret used by any finger. Useful for estimating reach difficulty.
    public var highestFret: Int {
        targets.map(\.fret).max() ?? 0
    }
}
