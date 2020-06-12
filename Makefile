AWS_STACK_NAME=swift-aws-lambda-template

DOCKER_IMAGE=swift-lambda-builder
DEPLOY_PACKAGES=HelloWorldAPI
SWIFT_RUNTIME_LAYER=.build/lambda/swift.zip

.PHONY: clean
clean:
	rm -rf .build/lambda

.PHONY: lint
lint:
	swift-format lint -r Package.swift Sources Tests

.PHONY: format
format:
	swift-format format -i -r Package.swift Sources Tests

.PHONY: run
run:
	swift run

.PHONY: test
test:
	swift test

.PHONY: package
package_executables:
	docker run \
	  --rm \
	  --volume "$(shell pwd)/:/src" \
	  --workdir "/src/" \
	  ${DOCKER_IMAGE} \
	  bash -c "for executable in ${DEPLOY_PACKAGES}; do scripts/package.sh \$${executable}; done"

${SWIFT_RUNTIME_LAYER}:
	docker run \
	  --rm \
	  --volume "$(shell pwd)/:/src" \
	  --workdir "/src/" \
	  ${DOCKER_IMAGE} \
	  scripts/package.sh swift true

package_libs: ${SWIFT_RUNTIME_LAYER}

package_all: package_executables package_libs

.PHONY: deploy
deploy: package_all
	sam deploy --s3-bucket=${AWS_DEPLOY_BUCKET} \
	  --stack-name=${AWS_STACK_NAME} \
	  --capabilities=CAPABILITY_IAM
