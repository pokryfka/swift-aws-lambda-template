// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "swift-aws-lambda-template",
    products: [
        // lambda handler, uses PureSwift JSON encoder/decoder
        .executable(name: "HelloWorldAPI", targets: ["HelloWorldAPI"]),
        // shared AWS Lambda code
        .library(name: "AWSLambdaUtils", targets: ["AWSLambdaUtils"]),
        // shared business logic
        .library(name: "HelloWorld", targets: ["HelloWorld"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/fabianfett/pure-swift-json.git", .upToNextMinor(from: "0.5.0")),
    ],
    targets: [
        .target(
            name: "HelloWorldAPI",
            dependencies: [
                .byName(name: "HelloWorld"),
                .byName(name: "AWSLambdaUtils"),
                .product(name: "AWSLambdaRuntimeCore", package: "swift-aws-lambda-runtime"),
            ]
        ),
        .target(
            name: "AWSLambdaUtils",
            dependencies: [
                .product(name: "AWSLambdaRuntimeCore", package: "swift-aws-lambda-runtime"),
                .product(name: "PureSwiftJSON", package: "pure-swift-json"),
            ]
        ),
        .target(
            name: "HelloWorld",
            dependencies: [
            ]
        ),
        .testTarget(
            name: "HelloWorldTests",
            dependencies: [.target(name: "HelloWorld")]
        ),
    ]
)
