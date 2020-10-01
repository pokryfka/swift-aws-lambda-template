# Swift AWS Lambda Template

![Build](https://github.com/pokryfka/swift-aws-lambda-template/workflows/Build/badge.svg)
![Package](https://github.com/pokryfka/swift-aws-lambda-template/workflows/Package/badge.svg)

An opinionated template for deploying serverless functions to [AWS Lambda](https://aws.amazon.com/lambda/) using [Swift AWS Lambda Runtime](https://github.com/swift-server/swift-aws-lambda-runtime/).

**Goals**:

- streamline deployment
- promote best practices
- improve performance

## Features

- [x] build and deploy with single `make deploy`
- [x] provision all resources using [AWS Cloud​Formation](https://aws.amazon.com/cloudformation/) (with help from [AWS SAM CLI](https://github.com/awslabs/serverless-application-model))
- [x] ~~tracing using [AWS X-Ray SDK for Swift](https://github.com/pokryfka/aws-xray-sdk-swift)~~ TODO: restore
- [x] CI workflows using [GitHub Actions](https://github.com/features/actions)
- [x] code formatting using [swiftformat](https://github.com/nicklockwood/SwiftFormat)
- [x] generate documentation using [swift-doc](https://github.com/SwiftDocOrg/swift-doc)

## Requirements

- [Swift](https://swift.org) compiler and [Package Manager](https://swift.org/package-manager/) - both included in [XCode](https://developer.apple.com/xcode/)
- [Docker](https://docs.docker.com/docker-for-mac/install/)
- [Amazon Web Services (AWS)](https://aws.amazon.com) Account
- [AWS Serverless Application Model (SAM)](https://github.com/awslabs/serverless-application-model) CLI
- [GNU Make](https://www.gnu.org/software/make/)
- [swiftformat](https://github.com/nicklockwood/SwiftFormat)

## Overview

The template contains code with two [AWS Lambda](https://aws.amazon.com/lambda/) functions:

- *HelloWorldAPI* handling [Amazon API Gateway](https://aws.amazon.com/api-gateway/) events

as well as a [AWS SAM template](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-specification.html) used to deploy them using [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-command-reference.html).

Since *SAM CLI* does not support Swift, a [Docker](https://docs.docker.com/docker-for-mac/install/) image is created and used to cross compile and package Swift code to run in *AWS Lambda* environment.

## Packages

requires SAM CLI 1.1.0

```
sam build HelloWorldAPIFunction
```

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

The *HelloWorldAPI* endpoint is printed after successful deployment, example: `https://xxx.execute-api.us-east-1.amazonaws.com/Prod/hello/` 

### Troubleshooting

When prompted, confirm that it is okay to deploy an endpoint without authorization, [see](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-deploying.html):

```
HelloWorldAPIFunction may not have authorization defined, Is this okay? [y/N]: y
```

## Testing

### Unit testing

Build and run tests:

```
$ swift test
```

### Invoking events (locally)

Set the `LOCAL_LAMBDA_SERVER_ENABLED` environment variable to `true` .

#### HelloWorldAPI

Build and run Lambda:

```
$ swift run HelloWorldAPI
```

Invoke the Lambda with `curl`:

```
$ curl --header "Content-Type: application/json" \
  --request POST --data @events/api2.json \
  http://localhost:7000/invoke
```

or with [HTTPie](https://httpie.org):

```
$ http POST http://localhost:7000/invoke @events/api2.json
```

## Developing

### Code Formatting

Format code using [swiftformat](https://github.com/nicklockwood/SwiftFormat):

```
swiftformat .
```

Consider creating [Git pre-commit hook](https://github.com/nicklockwood/SwiftFormat#git-pre-commit-hook)

```
echo 'swiftformat --lint .' > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## GitHub Actions

- [Test](.github/workflows/test.yml) - Run tests
- [Package](.github/workflows/package.yml) - Tests creating of packages with lambda functions
- [Lint](.github/workflows/lint.yml) - validates code formatting using [swiftformat](https://github.com/nicklockwood/SwiftFormat)
- [Documentation](.github/workflows/documentation.yml) generates documentation using [swift-doc](https://github.com/SwiftDocOrg/swift-doc)

Note [github-wiki-publish-action](https://github.com/SwiftDocOrg/github-wiki-publish-action) used by [Documentation](.github/workflows/documentation.yml) workflow requires that your repository has the following:

- A wiki with at least one page in it
- A secret named `GH_PERSONAL_ACCESS_TOKEN` with a Github personal access token with "repo" authorization
