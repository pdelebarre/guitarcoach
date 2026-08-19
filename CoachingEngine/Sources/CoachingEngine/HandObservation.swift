import Foundation

/// A single observed fingertip, expressed in neck-relative normalized
/// coordinates (0...1 along each axis) after the vision layer has mapped
/// image-space landmarks into neck space. `x` runs across the strings
/// (1st string near 0, 6th string near 1 for a standard right-handed top-down
/// view); `y` runs down the neck from the nut (0) toward the bridge (1).
public struct ObservedFingertip: Sendable {
    public let finger: Finger
    public let x: Double
    public let y: Double
    /// Vision landmark confidence in 0...1.
    public let confidence: Double

    public init(finger: Finger, x: Double, y: Double, confidence: Double) {
        self.finger = finger
        self.x = x
        self.y = y
        self.confidence = confidence
    }
}

/// One observation of a fretting hand attempting a chord shape.
public struct HandObservation: Sendable {
    public let fingertips: [ObservedFingertip]
    public init(fingertips: [ObservedFingertip]) {
        self.fingertips = fingertips
    }

    public func fingertip(for finger: Finger) -> ObservedFingertip? {
        fingertips.first { $0.finger == finger }
    }
}
