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
        .target(name: "TomateaCore", resources: [.process("Resources")]),
        .executableTarget(name: "Tomatea", dependencies: ["TomateaCore"], resources: [.process("Resources")]),
        .testTarget(name: "TomateaTests", dependencies: ["TomateaCore"])
    ]
)
