# swift-aws-lambda-template

A description of this package.

## Requirements

- [Docker](https://docs.docker.com/docker-for-mac/install/)
- [Amazon Web Services Account](https://aws.amazon.com)

## Testing locally

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

Build the Lambda function for the AWS Lambda Environment:

```
$ docker run \
--rm \
--volume "$(pwd)/:/src" \
--workdir "/src/" \
swift-lambda-builder \
swift build --product HelloWorldAPI -c release
```

Package the Lambda function:

```
$ docker run \
--rm \
--volume "$(pwd)/:/src" \
--workdir "/src/" \
swift-lambda-builder \
scripts/package.sh HelloWorldAPI
```

## References

- [Introducing Swift AWS Lambda Runtime](https://swift.org/blog/aws-lambda-runtime) by Tom Dordon
- [Getting started with Swift on AWS Lambda](https://fabianfett.de/getting-started-with-swift-aws-lambda-runtime) by Fabian Fett
