# swift-aws-lambda-template

![Build](https://github.com/pokryfka/swift-aws-lambda-template/workflows/Build/badge.svg)
![Package](https://github.com/pokryfka/swift-aws-lambda-template/workflows/Package/badge.svg)

A template for deploying Lambda functions with Swift AWS Lambda Runtime.

## Requirements

- [Swift](https://swift.org) compiler and [Package Manager](https://swift.org/package-manager/) - both included in [XCode](https://developer.apple.com/xcode/)
- [Docker](https://docs.docker.com/docker-for-mac/install/)
- [Amazon Web Services (AWS)](https://aws.amazon.com) Account
- [AWS Serverless Application Model (SAM)](https://github.com/awslabs/serverless-application-model) CLI
- [GNU Make](https://www.gnu.org/software/make/)
- [swift-format](https://github.com/apple/swift-format)

## Overview

The template contains code with two [AWS Lambda](https://aws.amazon.com/lambda/) functions:

- *HelloWorldAPI* handling [Amazon API Gateway](https://aws.amazon.com/api-gateway/) events
- *HelloWorldScheduled* handling [Amazon CloudWatch](https://aws.amazon.com/cloudwatch/) scheduled events

as well as a [AWS SAM template](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-specification.html) used to deploy them using [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-command-reference.html).

Since *SAM CLI* does not support Swift, a [Docker](https://docs.docker.com/docker-for-mac/install/) image is created and used to cross compile and package Swift code to run in *AWS Lambda* environment.

## Configuration

- `Package.swift` - [Swift Package Manager](https://swift.org/package-manager/) manifest file defining the package’s name, its contents and dependencies

- `template.yaml` - [AWS SAM Template](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-specification.html) defining the application's AWS resources

- `samconfig.toml` - [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-config.html) project-level configuration file

- [Swift AWS Lambda Runtime Configuration](https://github.com/swift-server/swift-aws-lambda-runtime) can be fine tuned using environment variables

## Deploying to AWS Lambda

Build and deploy:

```
$ make deploy
```

This will:

- build Docker image used to cross compile the code (if it does not exist)
- cross compile and package Lambda functions and Swift Linux Runtime Lambda Layer
- prompt to configure AWS SAM project (if `samconfig.toml` does not exist)
- deploy (create or update) AWS resources defined in `template.yaml` including Lambda functions and layers 

Note that, once deployed, the *HelloWorldScheduled* will be invoked every 5 minutes. Remove in [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/) or using [AWS CLI](https://github.com/aws/aws-cli).

## Testing

### Unit testing

Build and run tests:

```
$ swift test
```

### Invoking events (locally)

#### HelloWorldAPI

Build and run Lambda:

```
swift run HelloWorldAPI
```

Invoke the Lambda with `curl`:

```
$ curl --header "Content-Type: application/json" \
  --request POST --data @events/api.json \
  http://localhost:7000/invoke
```

or with [HTTPie](https://httpie.org):

```
$ http POST http://localhost:7000/invoke @events/api.json
```

#### HelloWorldScheduled

Build and run Lambda:

```
swift run HelloWorldScheduled
```

Invoke the Lambda with `curl`:

```
$ curl --header "Content-Type: application/json" \
  --request POST --data @events/scheduled.json \
  http://localhost:7000/invoke
```

or with [HTTPie](https://httpie.org):

```
$ http POST http://localhost:7000/invoke @events/scheduled.json
```

## References

- [Introducing Swift AWS Lambda Runtime](https://swift.org/blog/aws-lambda-runtime) by Tom Dordon
- [Getting started with Swift on AWS Lambda](https://fabianfett.de/getting-started-with-swift-aws-lambda-runtime) by Fabian Fett
- [AWS SDK Swift](https://github.com/swift-aws/aws-sdk-swift)
