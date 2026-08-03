// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HawkinsKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "HawkinsKit", targets: ["HawkinsKit"]),
    ],
    targets: [
        .target(name: "HawkinsKit"),
        .testTarget(name: "HawkinsKitTests", dependencies: ["HawkinsKit"]),
    ]
)
