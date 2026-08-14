// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Atrium",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "Atrium", targets: ["Atrium"]),
        .library(name: "AtriumCore", targets: ["AtriumCore"]),
    ],
    dependencies: [],
    targets: [
        .systemLibrary(
            name: "CSQLite",
            pkgConfig: "sqlite3"
        ),
        .target(
            name: "AtriumCore",
            dependencies: ["CSQLite"],
            path: "Sources/AtriumCore",
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ScreenCaptureKit"),
                .linkedFramework("Security"),
                .linkedFramework("Speech"),
                .linkedFramework("UserNotifications"),
            ]
        ),
        .executableTarget(
            name: "Atrium",
            dependencies: ["AtriumCore"],
            path: "Sources/Atrium",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
            ]
        ),
        .testTarget(
            name: "AtriumCoreTests",
            dependencies: ["AtriumCore"],
            path: "Tests/AtriumCoreTests"
        ),
        .testTarget(
            name: "AtriumTests",
            dependencies: ["Atrium"],
            path: "Tests/AtriumTests"
        ),
    ]
)
