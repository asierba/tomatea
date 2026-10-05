// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Pomodoro",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Pomodoro", targets: ["Pomodoro"]),
        .library(name: "PomodoroCore", targets: ["PomodoroCore"])
    ],
    targets: [
        .target(name: "PomodoroCore"),
        .executableTarget(name: "Pomodoro", dependencies: ["PomodoroCore"]),
        .testTarget(name: "PomodoroTests", dependencies: ["PomodoroCore"])
    ]
)
