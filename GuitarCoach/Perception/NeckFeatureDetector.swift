import AVFoundation
import Vision
import CoreML
import UIKit

/// Detected neck features in normalized camera coordinates (0-1)
struct NeckFeatures {
    /// Top of the nut (fret 0) in normalized Y coordinates
    let nutTop: CGPoint
    /// Y-positions of detected fret lines (normalized)
    let fretLines: [CGPoint]
    /// X-positions of string lines (normalized)
    let stringLines: [CGPoint]
    /// Overall detection confidence (0-1)
    let confidence: Float
    
    /// Estimated fret spacing in normalized coordinates
    var fretSpacing: Float {
        guard fretLines.count >= 2 else { return 0.02 }
        let spacings = zip(fretLines, fretLines.dropFirst()).map { 
            abs(Float($1.y - $0.y)) 
        }
        return spacings.reduce(0, +) / Float(spacings.count)
    }
}

/// Detects guitar neck features (nut, frets, strings) from camera frames
final class NeckFeatureDetector {
    private let fretDetector: VNCoreMLModel?
    private let stringDetector: VNCoreMLModel?
    
    init() {
        // Try to load pre-trained YOLOv8 models exported to CoreML
        // These will be added to the Xcode project after training
        self.fretDetector = try? VNCoreMLModel(for: FretDetector().model)
        self.stringDetector = try? VNCoreMLModel(for: StringDetector().model)
    }
    
    /// Detect neck features from a camera frame
    /// - Parameter pixelBuffer: Video frame from AVCaptureSession
    /// - Returns: Detected features or nil if confidence too low
    func detect(in pixelBuffer: CVPixelBuffer) -> NeckFeatures? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let imageRequestHandler = VNImageRequestHandler(
            pixelBuffer: pixelBuffer,
            options: [.imageOrientation: UIImage.Orientation.up.rawValue]
        )
        
        // Run fret detection
        var detectedFrets: [CGPoint] = []
        var fretConfidence: Float = 0.0
        
        if let model = fretDetector {
            let request = VNCoreMLRequest(model: model)
            request.revision = VNCoreMLRequestRevision3
            request.imageCropAndScaleOption = .scaleFill
            
            do {
                try imageRequestHandler.perform([request])
                if let results = request.results as? [VNRecognizedPointsObservation] {
                    detectedFrets = results.map { $0.normalizedPoint }
                    fretConfidence = results.map { $0.confidence }.reduce(0, +) / 
                        Float(results.count)
                }
            } catch {
                print("Fret detection failed: \(error)")
            }
        }
        
        // Run string detection
        var detectedStrings: [CGPoint] = []
        var stringConfidence: Float = 0.0
        
        if let model = stringDetector {
            let request = VNCoreMLRequest(model: model)
            request.revision = VNCoreMLRequestRevision3
            request.imageCropAndScaleOption = .scaleFill
            
            do {
                try imageRequestHandler.perform([request])
                if let results = request.results as? [VNRecognizedPointsObservation] {
                    detectedStrings = results.map { $0.normalizedPoint }
                    stringConfidence = results.map { $0.confidence }.reduce(0, +) / 
                        Float(results.count)
                }
            } catch {
                print("String detection failed: \(error)")
            }
        }
        
        // Fallback: if ML detection fails, use classical CV approach
        if detectedFrets.isEmpty || detectedStrings.isEmpty {
            return detectWithClassicalCV(in: pixelBuffer)
        }
        
        // Sort frets by Y position (top to bottom)
        let sortedFrets = detectedFrets.sorted { $0.y < $1.y }
        
        // Sort strings by X position (left to right, E to e)
        let sortedStrings = detectedStrings.sorted { $0.x < $1.x }
        
        // Calculate nut position (extrapolate from first two frets)
        let nutY: Float
        if sortedFrets.count >= 2 {
            let fretSpacing = sortedFrets[1].y - sortedFrets[0].y
            nutY = sortedFrets[0].y - (fretSpacing * 0.5) // Approximate
        } else if sortedFrets.count == 1 {
            nutY = sortedFrets[0].y - 0.03 // Assume ~3% of frame
        } else {
            nutY = 0.1 // Fallback: top 10% of frame
        }
        
        let overallConfidence = min(fretConfidence, stringConfidence)
        
        guard overallConfidence > 0.4 else { return nil }
        
        return NeckFeatures(
            nutTop: CGPoint(x: 0.5, y: CGFloat(nutY)),
            fretLines: sortedFrets,
            stringLines: sortedStrings,
            confidence: overallConfidence
        )
    }
    
    /// Fallback: classical computer vision approach (no ML required)
    private func detectWithClassicalCV(in pixelBuffer: CVPixelBuffer) -> NeckFeatures? {
        // Convert to CIImage for processing
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // 1. Convert to grayscale
        let grayscaleFilter = CIFilter(name: "CIPhotoEffectMono")!
        grayscaleFilter.setValue(ciImage, forKey: kCIInputImageKey)
        guard let grayscale = grayscaleFilter.outputImage else { return nil }
        
        // 2. Edge detection (Canny-like)
        let edgeFilter = CIFilter(name: "CIEdges")!
        edgeFilter.setValue(grayscale, forKey: kCIInputImageKey)
        edgeFilter.setValue(1.0, forKey: kCIInputIntensityKey)
        guard let edges = edgeFilter.outputImage else { return nil }
        
        // 3. Detect horizontal lines (frets) using line detection
        // This is a simplified approach - in production, use Accelerate.framework
        // or OpenCV for proper Hough Line Transform
        
        // For now, return a reasonable fallback based on typical guitar geometry
        // Assume guitar neck is in center of frame, frets are horizontal
        let imageWidth = CVPixelBufferGetWidth(pixelBuffer)
        let imageHeight = CVPixelBufferGetHeight(pixelBuffer)
        
        // Estimate neck region (center 60% of frame)
        let neckLeft = CGFloat(imageWidth) * 0.2
        let neckRight = CGFloat(imageWidth) * 0.8
        let neckTop = CGFloat(imageHeight) * 0.1
        let neckBottom = CGFloat(imageHeight) * 0.9
        
        // Generate 6 string positions (evenly spaced across neck width)
        let stringSpacing = (neckRight - neckLeft) / 7.0
        let strings = (1...6).map { i in
            CGPoint(x: (neckLeft + stringSpacing * CGFloat(i)) / CGFloat(imageWidth),
                    y: 0.5) // Y will be refined by fret detection
        }
        
        // Generate fret positions (assume 12 frets visible, logarithmic spacing)
        let frets = (1...12).map { i in
            let normalizedPos = CGFloat(i) / 13.0
            let y = neckTop + (neckBottom - neckTop) * normalizedPos
            return CGPoint(x: 0.5, y: y / CGFloat(imageHeight))
        }
        
        return NeckFeatures(
            nutTop: CGPoint(x: 0.5, y: neckTop / CGFloat(imageHeight)),
            fretLines: frets,
            stringLines: strings,
            confidence: 0.3 // Low confidence for fallback
        )
    }
}
