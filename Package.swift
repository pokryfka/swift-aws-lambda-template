// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "swift-aws-lambda-template",
    platforms: [
        .macOS(.v10_13),
    ],
    products: [
        .executable(name: "HelloWorldAPI", targets: ["HelloWorldAPI"]),
        .executable(name: "HelloWorldScheduled", targets: ["HelloWorldScheduled"]),
        .executable(name: "HelloWorldResolver", targets: ["HelloWorldResolver"]),
        .library(name: "HelloWorld", targets: ["HelloWorld"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", .upToNextMajor(from: "0.2.0")),
        .package(url: "https://github.com/swift-server/swift-backtrace.git", .upToNextMajor(from: "1.2.0")),
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
            ]
        ),
        .target(
            name: "HelloWorldScheduled",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-runtime"),
                .product(name: "Backtrace", package: "swift-backtrace"),
                .byName(name: "HelloWorld"),
            ]
        ),
        .target(
            name: "HelloWorldResolver",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-runtime"),
                .product(name: "Backtrace", package: "swift-backtrace"),
                .product(name: "AnyCodable", package: "AnyCodable"),
                .byName(name: "HelloWorld"),
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
    ]
)
