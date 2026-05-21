// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "hapa-crypto-node",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "hapa-crypto-node", targets: ["hapa-crypto-node"]),
        .library(name: "HapaCrypto", targets: ["HapaCrypto"]),
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "HapaCrypto",
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
            ],
            path: "Sources/HapaCrypto"
        ),
        .executableTarget(
            name: "hapa-crypto-node",
            dependencies: [
                "HapaCrypto",
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/hapa-crypto-node"
        ),
        .testTarget(
            name: "hapa-crypto-nodeTests",
            dependencies: ["HapaCrypto"],
            path: "Tests/hapa-crypto-nodeTests"
        ),
    ]
)
