// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "jotty",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(name: "jotty", targets: ["jotty"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.6.1"),
    ],
    targets: [
        .target(
            name: "TranscriptionCore",
            dependencies: []
        ),
        .executableTarget(
            name: "jotty",
            dependencies: [
                "TranscriptionCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        )
    ]
)
