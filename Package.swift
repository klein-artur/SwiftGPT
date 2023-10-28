// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftGPT",
    platforms: [
        .macOS(.v12),
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "SwiftGPT",
            targets: ["GPTConnector"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "GPTConnector",
            dependencies: []),
        .testTarget(
            name: "GPTConnectorTests",
            dependencies: ["GPTConnector"]),
    ]
)
