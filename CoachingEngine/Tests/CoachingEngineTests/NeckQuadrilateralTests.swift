import XCTest
import CoreGraphics
@testable import CoachingEngine

final class NeckQuadrilateralTests: XCTestCase {
    func testProjectMapsCornersToNeckSpace() {
        // An axis-aligned neck: top edge spans x 0...1 at y 1, bottom edge at y 0.
        let quad = NeckQuadrilateral(
            topLeft: CGPoint(x: 0, y: 1),
            topRight: CGPoint(x: 1, y: 1),
            bottomLeft: CGPoint(x: 0, y: 0),
            bottomRight: CGPoint(x: 1, y: 0)
        )
        XCTAssertEqual(quad.project(CGPoint(x: 0, y: 1)).x, 0, accuracy: 1e-6)
        XCTAssertEqual(quad.project(CGPoint(x: 0, y: 1)).y, 0, accuracy: 1e-6)
        XCTAssertEqual(quad.project(CGPoint(x: 1, y: 0)).x, 1, accuracy: 1e-6)
        XCTAssertEqual(quad.project(CGPoint(x: 1, y: 0)).y, 1, accuracy: 1e-6)
    }

    func testProjectCenter() {
        let quad = NeckQuadrilateral(
            topLeft: CGPoint(x: 0, y: 1),
            topRight: CGPoint(x: 1, y: 1),
            bottomLeft: CGPoint(x: 0, y: 0),
            bottomRight: CGPoint(x: 1, y: 0)
        )
        let center = quad.project(CGPoint(x: 0.5, y: 0.5))
        XCTAssertEqual(center.x, 0.5, accuracy: 1e-6)
        XCTAssertEqual(center.y, 0.5, accuracy: 1e-6)
    }

    func testAspectRatioIsHighForNeck() {
        // Long thin neck: fret axis is 1.0, string axis is 0.2.
        let quad = NeckQuadrilateral(
            topLeft: CGPoint(x: 0.4, y: 1),
            topRight: CGPoint(x: 0.6, y: 1),
            bottomLeft: CGPoint(x: 0.4, y: 0),
            bottomRight: CGPoint(x: 0.6, y: 0)
        )
        XCTAssertEqual(quad.aspectRatio, 5.0, accuracy: 1e-6)
    }

    func testArea() {
        let quad = NeckQuadrilateral(
            topLeft: CGPoint(x: 0, y: 1),
            topRight: CGPoint(x: 1, y: 1),
            bottomLeft: CGPoint(x: 0, y: 0),
            bottomRight: CGPoint(x: 1, y: 0)
        )
        XCTAssertEqual(quad.area, 1.0, accuracy: 1e-6)
    }

    func testDegenerateQuadrilateralReturnsCenter() {
        let quad = NeckQuadrilateral(
            topLeft: CGPoint(x: 0.5, y: 0.5),
            topRight: CGPoint(x: 0.5, y: 0.5),
            bottomLeft: CGPoint(x: 0.5, y: 0.5),
            bottomRight: CGPoint(x: 0.5, y: 0.5)
        )
        let result = quad.project(CGPoint(x: 0.1, y: 0.9))
        XCTAssertEqual(result.x, 0.5)
        XCTAssertEqual(result.y, 0.5)
    }
}
