// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LockSmith",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "LockSmith",
            targets: ["LockSmith"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Ponyboy47/TrailBlazer.git", .upToNextMajor(from: "0.14.0")),
        .package(url: "https://github.com/Ponyboy47/ErrNo.git", .upToNextMinor(from: "0.4.2")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "LockSmith",
            dependencies: ["TrailBlazer", "ErrNo"]),
        .testTarget(
            name: "LockSmithTests",
            dependencies: ["LockSmith", "TrailBlazer"]),
    ]
)
