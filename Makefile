AWS_STACK_NAME=swift-aws-lambda-template

.PHONY: clean
clean:
	rm -rf .build/lambda

.PHONY: run_local
run_local:
	swift run

.PHONY: build_aws
build_aws:
	docker run \
	  --rm \
	  --volume "$(shell pwd)/:/src" \
	  --workdir "/src/" \
	  swift-lambda-builder \
	  swift build --product HelloWorldAPI -c release

.PHONY: package
package: build_aws
	docker run \
	  --rm \
	  --volume "$(shell pwd)/:/src" \
	  --workdir "/src/" \
	  swift-lambda-builder \
	  scripts/package.sh HelloWorldAPI

.PHONY: deploy
deploy: package
	sam deploy --s3-bucket=${AWS_DEPLOY_BUCKET} \
	  --stack-name=${AWS_STACK_NAME} \
	  --capabilities=CAPABILITY_IAM
