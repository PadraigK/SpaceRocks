// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let fork = "PadraigK" // migueldeicaza

let package = Package(
    name: "SpaceRocks",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "SpaceRocks",
            type: .dynamic,
            targets: ["SpaceRocks"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/PadraigK/SGHelpers", branch: "main"),
        .package(url: "https://github.com/\(fork)/SwiftGodot", branch: "main"),
    ],
    targets: [
        .target(
            name: "SpaceRocks",
            dependencies: [
                "SwiftGodot",
                "SGHelpers",
                .product(name: "SwiftGodotMacros", package: "SwiftGodot"),
            ],
            swiftSettings: [.unsafeFlags(["-suppress-warnings"])],
            linkerSettings: [
                .unsafeFlags(
                    ["-Xlinker", "-undefined",
                     "-Xlinker", "dynamic_lookup"]
                ),
            ]
        ),
        .testTarget(
            name: "SpaceRocksTests",
            dependencies: ["SpaceRocks"]
        ),
    ]
)
