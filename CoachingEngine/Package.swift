// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CoachingEngine",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "CoachingEngine", targets: ["CoachingEngine"])
    ],
    targets: [
        .target(name: "CoachingEngine"),
        .testTarget(name: "CoachingEngineTests", dependencies: ["CoachingEngine"])
    ]
)
