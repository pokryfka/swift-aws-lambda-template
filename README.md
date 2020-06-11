# swift-aws-lambda-template

A template for deploying Lambda functions with Swift AWS Lambda Runtime.

## Requirements

- Swift compiler and Swift Package Manager - both included in [XCode](https://developer.apple.com/xcode/)
- [Docker](https://docs.docker.com/docker-for-mac/install/)
- [Amazon Web Services Account](https://aws.amazon.com)
- [AWS Serverless Application Model](https://github.com/awslabs/serverless-application-model)
- [GNU Make](https://www.gnu.org/software/make/)

## Configuration

See [Swift AWS Lambda Runtime Configuration](https://github.com/swift-server/swift-aws-lambda-runtime#configuration).

The can be configured using the `LOG_LEVEL` environment variable

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

Build docker image:

```
$ docker build -t swift-lambda-builder .
```

Configure the environment:

```
$ export AWS_PROFILE=profile_name
$ export AWS_DEPLOY_BUCKET=bucket_name
```

Build and deploy:

```
$ make deploy
```

## References

- [Introducing Swift AWS Lambda Runtime](https://swift.org/blog/aws-lambda-runtime) by Tom Dordon
- [Getting started with Swift on AWS Lambda](https://fabianfett.de/getting-started-with-swift-aws-lambda-runtime) by Fabian Fett
