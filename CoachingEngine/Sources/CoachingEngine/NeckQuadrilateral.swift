import CoreGraphics
import Foundation

/// Represents the detected guitar neck/fretboard region in the image as a
/// quadrilateral (in Vision normalized coordinates, origin bottom-left) and maps
/// image-space points into neck-relative normalized coordinates.
///
/// The fret axis runs from the `top` edge (nut / fret 0 side) down to the
/// `bottom` edge (toward the bridge, higher frets). The string axis runs along
/// the top edge (1st string near 0, 6th string near 1). A point is expressed as
/// the linear combination of the two edge vectors that reaches it.
public struct NeckQuadrilateral: Sendable {
    public let topLeft: CGPoint
    public let topRight: CGPoint
    public let bottomLeft: CGPoint
    public let bottomRight: CGPoint

    public init(topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
    }

    /// The fret (long) axis vector, pointing from the nut edge toward the bridge.
    private var fretVector: CGVector {
        CGVector(dx: bottomLeft.x - topLeft.x, dy: bottomLeft.y - topLeft.y)
    }

    /// The string (cross) axis vector, pointing across the top edge.
    private var stringVector: CGVector {
        CGVector(dx: topRight.x - topLeft.x, dy: topRight.y - topLeft.y)
    }

    /// Maps an image-space `point` into neck space: x in 0...1 across the
    /// strings, y in 0...1 from the nut (0) down the neck (1).
    /// Degenerate (zero-area) quadrilaterals return the center as a safe default.
    public func project(_ point: CGPoint) -> CGPoint {
        let fret = fretVector
        let string = stringVector
        let px = point.x - topLeft.x
        let py = point.y - topLeft.y

        let det = fret.dx * string.dy - fret.dy * string.dx
        guard abs(det) > 1e-9 else {
            return CGPoint(x: 0.5, y: 0.5)
        }

        let fretCoord = (px * string.dy - string.dx * py) / det
        let stringCoord = (fret.dx * py - px * fret.dy) / det
        return CGPoint(x: stringCoord, y: fretCoord)
    }

    /// The aspect ratio of the long edge over the short edge. A guitar neck is
    /// long and thin, so this is high (typically > 2).
    public var aspectRatio: Double {
        let fret = fretVector
        let string = stringVector
        let long = max(hypot(fret.dx, fret.dy), hypot(string.dx, string.dy))
        let short = min(hypot(fret.dx, fret.dy), hypot(string.dx, string.dy))
        guard short > 0 else { return 0 }
        return long / short
    }

    /// Area of the quadrilateral in normalized units (used to prefer larger necks).
    public var area: Double {
        let a = topLeft
        let b = topRight
        let c = bottomRight
        let d = bottomLeft
        return abs(shoelace(a, b, c, d))
    }

    private func shoelace(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ d: CGPoint) -> Double {
        0.5 * ((a.x * b.y - b.x * a.y)
             + (b.x * c.y - c.x * b.y)
             + (c.x * d.y - d.x * c.y)
             + (d.x * a.y - a.x * d.y))
    }
}
