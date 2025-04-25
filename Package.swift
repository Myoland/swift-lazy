// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-lazy",
    platforms: [.macOS(.v14), .iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "WantLazy", targets: ["WantLazy"]),
        .library(name: "TestHelper", targets: ["TestHelper"])
    ],
    dependencies: [
        .package(url: "https://github.com/thebarndog/swift-dotenv.git", from: "2.1.0"),
        .package(url: "https://github.com/apple/swift-http-types.git", from: "1.4.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.25.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "WantLazy",
            dependencies: [
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ]
        ),
        .target(
            name: "TestHelper",
            dependencies: [
                .product(name: "SwiftDotenv", package: "swift-dotenv"),
            ]
        ),
        .testTarget(
            name: "WantLazyTests",
            dependencies: ["WantLazy"]
        ),
    ]
)
