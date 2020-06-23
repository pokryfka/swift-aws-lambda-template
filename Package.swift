// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "swift-aws-lambda-template",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .executable(name: "HelloWorldAPI", targets: ["HelloWorldAPI"]),
        .executable(name: "HelloWorldScheduled", targets: ["HelloWorldScheduled"]),
        .library(name: "AWSXRayRecorder", targets: ["AWSXRayRecorder"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-server/swift-aws-lambda-runtime.git",
            .upToNextMajor(from: "0.2.0")),
        .package(
            url: "https://github.com/swift-server/swift-backtrace.git",
            .upToNextMajor(from: "1.2.0")),
        // AWSXRayRecorder
        .package(
            url: "https://github.com/swift-aws/aws-sdk-swift.git",
            .upToNextMinor(from: "5.0.0-alpha.4")),
        .package(
            url: "https://github.com/swift-server/async-http-client.git",
            .upToNextMinor(from: "1.0.0")),
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.16.1")),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/Flight-School/AnyCodable", from: "0.2.3"),

    ],
    targets: [
        .target(
            name: "HelloWorldAPI",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-runtime"),
                .product(name: "Backtrace", package: "swift-backtrace"),
                .byName(name: "HelloWorld"),
                .byName(name: "AWSXRayRecorder"),
            ]
        ),
        .target(
            name: "HelloWorldScheduled",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-runtime"),
                .product(name: "Backtrace", package: "swift-backtrace"),
                .byName(name: "HelloWorld"),
                .byName(name: "AWSXRayRecorder"),
            ]
        ),
        .target(
            name: "HelloWorld",
            dependencies: []
        ),
        .testTarget(
            name: "HelloWorldTests",
            dependencies: ["HelloWorld"]
        ),
        .target(
            name: "AWSXRayRecorder",
            dependencies: [
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSXRay", package: "aws-sdk-swift"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOConcurrencyHelpers", package: "swift-nio"),
                .product(name: "AnyCodable", package: "AnyCodable"),
            ]
        ),
        .testTarget(
            name: "AWSXRayRecorderTests",
            dependencies: ["AWSXRayRecorder"]
        ),
    ]
)
