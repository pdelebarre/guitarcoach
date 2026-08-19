import Foundation

/// A curated starter set of static chord shapes (the M2 MVP set), used by the
/// prototype's practice UI and by fixture tests.
public enum StarterChords {
    public static let cMajor = ChordShape(
        name: "C",
        targets: [
            .init(finger: .index, string: 2, fret: 1),
            .init(finger: .middle, string: 4, fret: 2),
            .init(finger: .ring, string: 5, fret: 3)
        ],
        hints: ["Index on B string, 1st fret", "Middle on D string, 2nd fret", "Ring on A string, 3rd fret"]
    )

    public static let gMajor = ChordShape(
        name: "G",
        targets: [
            .init(finger: .middle, string: 6, fret: 3),
            .init(finger: .index, string: 5, fret: 2),
            .init(finger: .ring, string: 1, fret: 3)
        ],
        hints: ["Middle on low E, 3rd fret", "Index on A string, 2nd fret", "Ring on high E, 3rd fret"]
    )

    public static let dMajor = ChordShape(
        name: "D",
        targets: [
            .init(finger: .index, string: 3, fret: 2),
            .init(finger: .middle, string: 1, fret: 2),
            .init(finger: .ring, string: 2, fret: 3)
        ],
        hints: ["Index on G string, 2nd fret", "Middle on high E, 2nd fret", "Ring on B string, 3rd fret"]
    )

    public static let eMinor = ChordShape(
        name: "Em",
        targets: [
            .init(finger: .middle, string: 5, fret: 2),
            .init(finger: .ring, string: 4, fret: 2)
        ],
        hints: ["Middle on A string, 2nd fret", "Ring on D string, 2nd fret"]
    )

    public static let aMinor = ChordShape(
        name: "Am",
        targets: [
            .init(finger: .index, string: 2, fret: 1),
            .init(finger: .middle, string: 3, fret: 2),
            .init(finger: .ring, string: 4, fret: 2)
        ],
        hints: ["Index on B string, 1st fret", "Middle on G string, 2nd fret", "Ring on D string, 2nd fret"]
    )

    /// Ordered starter path for the prototype.
    public static let all: [ChordShape] = [cMajor, gMajor, dMajor, eMinor, aMinor]
}
