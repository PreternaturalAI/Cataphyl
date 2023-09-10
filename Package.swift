// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "Cataphyl",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "Cataphyl",
            targets: [
                "Cataphyl"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/vmanot/CorePersistence.git", branch: "main"),
        .package(url: "https://github.com/vmanot/LargeLanguageModels.git", branch: "main"),
        .package(url: "https://github.com/vmanot/Swallow.git", branch: "master")
    ],
    targets: [
        .target(
            name: "Cataphyl",
            dependencies: [
                "CorePersistence",
                "LargeLanguageModels",
                "Swallow"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "CataphylTests",
            dependencies: [
                "Cataphyl"
            ],
            path: "Tests"
        )
    ]
)
