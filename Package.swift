// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DesignAlgorithmsKit",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "DesignAlgorithmsKit",
            targets: ["DesignAlgorithmsKit"]),
    ],
    // No package dependencies. Apple platforms only (CryptoKit, NSLock).
    dependencies: [],
    targets: [
        .target(
            name: "DesignAlgorithmsKit",
            dependencies: [],
            path: "Sources/DesignAlgorithmsKit",
            linkerSettings: [
                .linkedLibrary("z")
            ]
        ),
        .testTarget(
            name: "DesignAlgorithmsKitTests",
            dependencies: ["DesignAlgorithmsKit"],
            path: "Tests/DesignAlgorithmsKitTests",
            linkerSettings: [
                .linkedLibrary("z")
            ]
        ),
        // Tests that run system tools (gzip/gunzip); macOS only, skipped when the tools are missing.
        .testTarget(
            name: "DesignAlgorithmsKitIntegrationTests",
            dependencies: ["DesignAlgorithmsKit"],
            path: "Tests/DesignAlgorithmsKitIntegrationTests"
        ),
    ]
)
