# swift-aws-lambda-template

A template for deploying Lambda functions with Swift AWS Lambda Runtime.

## Requirements

- Swift compiler and Swift Package Manager - both included in [XCode](https://developer.apple.com/xcode/)
- [Docker](https://docs.docker.com/docker-for-mac/install/)
- [Amazon Web Services](https://aws.amazon.com) Account
- [AWS Serverless Application Model](https://github.com/awslabs/serverless-application-model) CLI
- [GNU Make](https://www.gnu.org/software/make/)
- [swift-format](https://github.com/apple/swift-format)

## Configuration

[Swift AWS Lambda Runtime Configuration](https://github.com/swift-server/swift-aws-lambda-runtime) can be fine tuned using environment variables.

[AWS SAM CLI Config](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-config.html) is created and saved in `samconfig.toml`.

## Testing locally

Compile and run `HelloWorldAPI` with `XCode` or in terminal:

```
$ LOG_LEVEL=debug make run_local
```

Invoke lambda with `curl`:

```
$ curl --header "Content-Type: application/json" \
  --request POST --data @events/api.json \
  http://localhost:7000/invoke
```

or with [HTTPie](https://httpie.org):

```
$ http POST http://localhost:7000/invoke @events/api.json
```

## Deploying to AWS Lambda

Build and deploy:

```
$ make deploy
```

Note that Docker image and SAM configuration will be created if they don't exist.

## References

- [Introducing Swift AWS Lambda Runtime](https://swift.org/blog/aws-lambda-runtime) by Tom Dordon
- [Getting started with Swift on AWS Lambda](https://fabianfett.de/getting-started-with-swift-aws-lambda-runtime) by Fabian Fett
- [AWS SDK Swift](https://github.com/swift-aws/aws-sdk-swift)
