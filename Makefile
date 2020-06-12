DEPLOY_PACKAGES=HelloWorldAPI

DOCKER_IMAGE=swift-lambda-builder
SWIFT_RUNTIME_LAYER=.build/lambda/swift.zip
SAM_CONFIG=samconfig.toml

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

.PHONY: build_docker
docker_image:
	docker inspect swift-lambda-builder > /dev/null 2>&1 || docker build -t swift-lambda-builder .

.PHONY: package
package_executables: docker_image
	docker run \
	  --rm \
	  --volume "$(shell pwd)/:/src" \
	  --workdir "/src/" \
	  ${DOCKER_IMAGE} \
	  bash -c "for executable in ${DEPLOY_PACKAGES}; do scripts/package.sh \$${executable}; done"

${SWIFT_RUNTIME_LAYER}: docker_image
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
	[ -f ${SAM_CONFIG} ] && sam deploy || sam deploy --guided
