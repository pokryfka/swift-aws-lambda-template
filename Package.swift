// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "swift-aws-lambda-template",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .executable(name: "HelloWorldAPI", targets: ["HelloWorldAPI"]),
        .library(name: "HelloWorld", targets: ["HelloWorld"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-server/swift-aws-lambda-runtime.git",
            .upToNextMajor(from: "0.1.0"))
    ],
    targets: [
        .target(
            name: "HelloWorldAPI",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-runtime"),
                .byName(name: "HelloWorld"),
            ]
        ),
        .target(
            name: "HelloWorld",
            dependencies: []
        ),
        .testTarget(
            name: "swift-aws-lambda-templateTests",
            dependencies: []
        ),
    ]
)
