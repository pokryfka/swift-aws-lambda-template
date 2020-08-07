// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "swift-aws-lambda-template",
    platforms: [
        .macOS(.v10_14), // TODO: remove after swift-aws-lambda-runtime fixes that
    ],
    products: [
        // lambda handler using default (Foundation) JSON encoder/decoder
        .executable(name: "HelloWorldAPI", targets: ["HelloWorldAPI"]),
        // lambda handler using PureSwift JSON encoder/decoder
        .executable(name: "HelloWorldAPIPerf", targets: ["HelloWorldAPIPerf"]),
        // shared AWS Lambda code
        .library(name: "AWSLambdaUtils", targets: ["AWSLambdaUtils"]),
        // shared business logic
        .library(name: "HelloWorld", targets: ["HelloWorld"]),
    ],
    dependencies: [
        //        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", .upToNextMajor(from: "0.2.0")),
//        .package(name: "swift-aws-lambda-runtime", path: "../swift-aws-lambda-runtime"),
        .package(url: "https://github.com/pokryfka/swift-aws-lambda-runtime.git", .branch("feature/tracing")),
//        .package(url: "https://github.com/pokryfka/aws-xray-sdk-swift.git", .upToNextMinor(from: "0.6.1")),
        .package(url: "https://github.com/pokryfka/aws-xray-sdk-swift.git", .branch("feature/foundation")),
//        .package(name: "aws-xray-sdk-swift", path: "../aws-xray-sdk-swift"),
        .package(url: "https://github.com/fabianfett/pure-swift-json.git", .upToNextMinor(from: "0.4.0")),
    ],
    targets: [
        .target(
            name: "HelloWorldAPI",
            dependencies: [
                .byName(name: "HelloWorld"),
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSXRaySDK", package: "aws-xray-sdk-swift"),
            ]
        ),
        .target(
            name: "HelloWorldAPIPerf",
            dependencies: [
                .byName(name: "HelloWorld"),
                .byName(name: "AWSLambdaUtils"),
                .product(name: "AWSLambdaRuntimeCore", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSXRayRecorder", package: "aws-xray-sdk-swift"),
                .product(name: "PureSwiftJSON", package: "pure-swift-json"),
            ]
        ),
        .target(
            name: "AWSLambdaUtils",
            dependencies: [
                .product(name: "AWSLambdaRuntimeCore", package: "swift-aws-lambda-runtime"),
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
