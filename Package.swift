// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "swift-aws-lambda-template",
    platforms: [
        .macOS(.v10_14),
    ],
    products: [
        .executable(name: "HelloWorldAPI", targets: ["HelloWorldAPI"]),
        .executable(name: "HelloWorldScheduled", targets: ["HelloWorldScheduled"]),
        .library(name: "HelloWorld", targets: ["HelloWorld"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", .upToNextMajor(from: "0.2.0")),
        .package(url: "https://github.com/swift-server/swift-backtrace.git", .upToNextMajor(from: "1.2.0")),
       .package(url: "https://github.com/pokryfka/aws-xray-sdk-swift.git", from: "0.3.0"),
    ],
    targets: [
        .target(
            name: "HelloWorldAPI",
            dependencies: [
                .byName(name: "HelloWorld"),
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-runtime"),
                .product(name: "Backtrace", package: "swift-backtrace"),
                .product(name: "AWSXRayRecorderLambda", package: "aws-xray-sdk-swift"),
            ]
        ),
        .target(
            name: "HelloWorldScheduled",
            dependencies: [
                .byName(name: "HelloWorld"),
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-runtime"),
                .product(name: "Backtrace", package: "swift-backtrace"),
                .product(name: "AWSXRayRecorderLambda", package: "aws-xray-sdk-swift"),
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
