// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Notive",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "Notive", targets: ["Notive"]),
        .library(name: "NotiveCore", targets: ["NotiveCore"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/sparkle-project/Sparkle",
            exact: "2.9.2"
        ),
    ],
    targets: [
        .systemLibrary(
            name: "CSQLite",
            pkgConfig: "sqlite3"
        ),
        .target(
            name: "NotiveCore",
            dependencies: ["CSQLite"],
            path: "Sources/NotiveCore",
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
            name: "Notive",
            dependencies: [
                "NotiveCore",
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources/Notive",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .unsafeFlags([
                    "-Xlinker", "-rpath",
                    "-Xlinker", "@executable_path/../Frameworks",
                ]),
            ]
        ),
        .testTarget(
            name: "NotiveCoreTests",
            dependencies: ["NotiveCore"],
            path: "Tests/NotiveCoreTests"
        ),
    ]
)
