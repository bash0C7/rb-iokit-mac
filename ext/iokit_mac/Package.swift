// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "IokitMac",
    platforms: [.macOS(.v27)],
    products: [
        .library(
            name: "IokitMac",
            type: .dynamic,
            targets: ["IokitMac"]
        ),
    ],
    targets: [
        .target(
            name: "IokitMac"
        ),
    ]
)
