// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var dependencies: [PackageDescription.Package.Dependency] = []

dependencies.append(contentsOf: [
    .package(url: "https://github.com/thebarndog/swift-dotenv.git", from: "2.1.0"),
    .package(url: "https://github.com/apple/swift-http-types.git", from: "1.4.0"),
    .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.8.2"),
    .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.1"),
])

let package = Package(
    name: "swift-lazy",
    platforms: [.macOS(.v14), .iOS(.v16)],
    products: [
        .library(name: "LazyKit", targets: ["LazyKit"]),
        .library(name: "TestKit", targets: ["TestKit"]),
        .library(name: "NetworkKit", targets: ["NetworkKit"])
    ],
    dependencies: dependencies,
    targets: [
        .target(
            name: "LazyKit",
            dependencies: [
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ]
        ),
        .target(
            name: "NetworkKit",
            dependencies: [
                "LazyKit",
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
            ]
        ),
        .target(
            name: "TestKit",
            dependencies: [
                .product(name: "SwiftDotenv", package: "swift-dotenv"),
            ]
        ),
        .testTarget(
            name: "LazyKitTests",
            dependencies: ["LazyKit"]
        ),
    ]
)
