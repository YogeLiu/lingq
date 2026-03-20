// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SRSKit",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "SRSKit", targets: ["SRSKit"]),
    ],
    targets: [
        .target(name: "SRSKit"),
        .testTarget(name: "SRSKitTests", dependencies: ["SRSKit"]),
    ]
)
