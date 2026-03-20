// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AudioPlayerKit",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "AudioPlayerKit", targets: ["AudioPlayerKit"]),
    ],
    dependencies: [
        .package(path: "../SharedModels"),
    ],
    targets: [
        .target(name: "AudioPlayerKit", dependencies: ["SharedModels"]),
        .testTarget(name: "AudioPlayerKitTests", dependencies: ["AudioPlayerKit"]),
    ]
)
