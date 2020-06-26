DEPLOY_PACKAGES=HelloWorldAPI HelloWorldScheduled

DOCKER_IMAGE=swift-lambda-builder
DOCKER_IMAGE_INFO=.build/${DOCKER_IMAGE}.json
SWIFT_RUNTIME_LAYER=.build/lambda/swift.zip
SWIFT_RELEASE_OPTS=-c release -Xswiftc -g
SAM_CONFIG=samconfig.toml

.PHONY: all
all: test_linux deploy

.PHONY: clean
clean:
	rm -rf .build

.PHONY: lint
lint:
	swift-format lint -r Package.swift Sources Tests

.PHONY: format
format:
	swift-format format -i -r Package.swift Sources Tests

.PHONY: test
test:
	swift test

${DOCKER_IMAGE_INFO}:
	docker inspect ${DOCKER_IMAGE} > /dev/null 2>&1 || docker build -t ${DOCKER_IMAGE} .
	mkdir -p `dirname ${DOCKER_IMAGE_INFO}`
	docker inspect ${DOCKER_IMAGE} > ${DOCKER_IMAGE_INFO}

.PHONY: test_linux
test_linux: ${DOCKER_IMAGE_INFO}
	docker run \
	  --rm \
	  --volume "$(shell pwd)/:/src" \
	  --workdir "/src/" \
	  ${DOCKER_IMAGE} \
	  swift test

.PHONY: build_linux
build_linux: ${DOCKER_IMAGE_INFO}
	docker run \
	  --rm \
	  --volume "$(shell pwd)/:/src" \
	  --workdir "/src/" \
	  ${DOCKER_IMAGE} \
	  bash -c "for product in ${DEPLOY_PACKAGES}; do swift build --product \$${product} ${SWIFT_RELEASE_OPTS}; done"

.PHONY: package
package_executables: ${DOCKER_IMAGE_INFO} build_linux
	docker run \
	  --rm \
	  --volume "$(shell pwd)/:/src" \
	  --workdir "/src/" \
	  ${DOCKER_IMAGE} \
	  bash -c "for executable in ${DEPLOY_PACKAGES}; do scripts/package.sh \$${executable}; done"

${SWIFT_RUNTIME_LAYER}: ${DOCKER_IMAGE_INFO}
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
