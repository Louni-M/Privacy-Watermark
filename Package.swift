// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PrivacyWatermark",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "WatermarkCore", targets: ["WatermarkCore"]),
        .executable(name: "PrivacyWatermark", targets: ["PrivacyWatermark"])
    ],
    targets: [
        .target(name: "WatermarkCore"),
        .executableTarget(name: "PrivacyWatermark", dependencies: ["WatermarkCore"]),
        .testTarget(name: "WatermarkCoreTests", dependencies: ["WatermarkCore"], resources: [.copy("Fixtures")]),
        .testTarget(name: "PrivacyWatermarkTests", dependencies: ["PrivacyWatermark", "WatermarkCore"])
    ]
)
