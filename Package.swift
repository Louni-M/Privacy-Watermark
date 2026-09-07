// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PassportFiligrane",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "WatermarkCore", targets: ["WatermarkCore"]),
        .executable(name: "PassportFiligrane", targets: ["PassportFiligrane"])
    ],
    targets: [
        .target(name: "WatermarkCore"),
        .executableTarget(name: "PassportFiligrane", dependencies: ["WatermarkCore"]),
        .testTarget(name: "WatermarkCoreTests", dependencies: ["WatermarkCore"], resources: [.copy("Fixtures")]),
        .testTarget(name: "PassportFiligraneTests", dependencies: ["PassportFiligrane", "WatermarkCore"])
    ]
)
