// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "OpenVoice",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "OpenVoice", targets: ["OpenVoice"])
    ],
    targets: [
        .executableTarget(
            name: "OpenVoice",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("SwiftData"),
                .linkedFramework("SwiftUI")
            ]
        )
    ]
)
