// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VocabularyKit",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "VocabularyKit", targets: ["VocabularyKit"]),
    ],
    dependencies: [
        .package(path: "../SharedModels"),
        .package(path: "../SRSKit"),
    ],
    targets: [
        .target(name: "VocabularyKit", dependencies: ["SharedModels", "SRSKit"]),
        .testTarget(name: "VocabularyKitTests", dependencies: ["VocabularyKit"]),
    ]
)
