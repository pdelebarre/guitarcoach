import AVFoundation
import CoachingEngine
import Foundation
import Observation

/// Wires camera capture -> Vision hand pose -> coaching geometry engine into a
/// single observable state the UI renders. The M0 prototype shows a live cue or
/// a repositioning request; it never persists frames.
@MainActor
@Observable
final class PracticeViewModel {
    let camera = CameraManager()
    private let recognizer = HandPoseRecognizer()
    private let engine = GeometryEngine()
    private let reference = NeckReference(visibleFrets: 4, fretTolerance: 0.35, minConfidence: 0.6)

    var currentChord = StarterChords.cMajor
    private(set) var feedback = Feedback(cues: [])
    private(set) var isMonitoring = false
    private var hasRequestedPermission = false

    var canUseCamera: Bool {
        camera.state != .permissionDenied
    }

    var primaryMessage: String {
        feedback.cues.first.map(render) ?? "Place your fingers for \(currentChord.name)."
    }

    var allMessages: [String] {
        feedback.cues.map(render)
    }

    func start() {
        guard !hasRequestedPermission else { return }
        hasRequestedPermission = true
        Task {
            await camera.requestAccess()
            guard camera.state != .permissionDenied else { return }
            isMonitoring = true
            await camera.start { [weak self] sampleBuffer in
                self?.process(sampleBuffer)
            }
        }
    }

    func stop() {
        camera.stop()
        isMonitoring = false
    }

    func toggleCamera() {
        camera.toggleCamera()
    }

    func cycleChord() {
        let all = StarterChords.all
        let currentIndex = all.firstIndex(of: currentChord) ?? 0
        let next = all[(currentIndex + 1) % all.count]
        currentChord = next
    }

    private func process(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        guard let detection = recognizer.detect(in: pixelBuffer), detection.detected else {
            setFeedback(Feedback(cues: [.lowConfidence(reason: "hand_not_detected")]))
            return
        }
        let result = engine.assess(observation: detection.observation,
                                   target: currentChord,
                                   reference: reference,
                                   handRotationDegrees: detection.handRotationDegrees)
        setFeedback(Feedback(cues: result.cues))
    }

    private func setFeedback(_ feedback: Feedback) {
        MainActor.assumeIsolated {
            self.feedback = feedback
        }
    }

    private func render(_ cue: FeedbackCue) -> String {
        switch cue {
        case .wrongFret(let finger, let expected, let actual):
            return "\(finger.displayName.capitalized) finger is on fret \(actual); move it to fret \(expected)."
        case .wrongString(let finger, let expected, let actual):
            return "\(finger.displayName.capitalized) finger is on string \(actual); move it to string \(expected)."
        case .fingerTooFarFromFret(let finger):
            return "\(finger.displayName.capitalized) finger is too far from the fret; place it just behind the fret."
        case .missingFinger(let finger):
            return "Place your \(finger.displayName) finger on the string."
        case .excessiveHandRotation(let degrees):
            return "Rotate your hand \(abs(degrees) > 0 ? "slightly" : "") so it faces the camera."
        case .lowConfidence:
            return "We can't see your hand clearly. Reposition your hand in the frame."
        }
    }
}
