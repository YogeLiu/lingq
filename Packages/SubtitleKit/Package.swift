// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SubtitleKit",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "SubtitleKit", targets: ["SubtitleKit"]),
    ],
    dependencies: [
        .package(path: "../SharedModels"),
    ],
    targets: [
        .target(name: "SubtitleKit", dependencies: ["SharedModels"]),
        .testTarget(name: "SubtitleKitTests", dependencies: ["SubtitleKit"]),
    ]
)
