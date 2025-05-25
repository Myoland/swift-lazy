// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var dependencies: [PackageDescription.Package.Dependency] = []

dependencies.append(contentsOf: [
    .package(url: "https://github.com/thebarndog/swift-dotenv.git", from: "2.1.0"),
    .package(url: "https://github.com/apple/swift-http-types.git", from: "1.4.0"),
])

#if os(macOS)
dependencies.append(contentsOf: [
    .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.25.2"),
])
#endif

let package = Package(
    name: "swift-lazy",
    platforms: [.macOS(.v14), .iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "LazyKit", targets: ["LazyKit"]),
        .library(name: "TestKit", targets: ["TestKit"])
    ],
    dependencies: dependencies,
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "LazyKit",
            dependencies: [
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "AsyncHTTPClient", package: "async-http-client", condition: .when(platforms: [.macOS])),
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
