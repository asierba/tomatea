// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Tomatea",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Tomatea", targets: ["Tomatea"]),
        .library(name: "TomateaCore", targets: ["TomateaCore"])
    ],
    targets: [
        .target(name: "TomateaCore"),
        .executableTarget(name: "Tomatea", dependencies: ["TomateaCore"]),
        .testTarget(name: "TomateaTests", dependencies: ["TomateaCore"])
    ]
)
