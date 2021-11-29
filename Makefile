qa: lint lint-shell build test scan-vulnerability
build: clean-tags build-cli build-fpm
push: build push-cli push-fpm
ci-push-cli: ci-docker-login push-cli
ci-push-fpm: ci-docker-login push-fpm

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(abspath $(patsubst %/,%,$(dir $(mkfile_path))))

.PHONY: *

BUILDINGIMAGE=*
#############################################################################################
# Docker PHP images build matrix ./build-php.sh (cli/fpm) (PHP version) (Alpine version)
#############################################################################################
# CLI
###########################################
build-cli: BUILDINGIMAGE=cli
build-cli: clean-tags
	./build-php.sh cli 7.4 3.14 4.1.2 4.2.0 latest
	./build-php.sh cli 7.3 3.14 4.1.2 4.2.0
	./build-php.sh cli 7.3 3.13 3.4.5 3.4.2
	./build-php.sh cli 7.2 3.12 3.4.5 3.4.2
	./build-php.sh cli 7.1 3.10 3.4.5 3.4.2

push-cli: BUILDINGIMAGE=cli
push-cli:
	cat ./tmp/build-${BUILDINGIMAGE}.tags | xargs -I % docker push %

test-cli: ./tmp/build-cli.tags
	xargs -I % ./test-cli.sh % < ./tmp/build-cli.tags

###########################################
# FPM
###########################################
build-fpm: BUILDINGIMAGE=fpm
build-fpm: clean-tags
	./build-php.sh fpm 7.4 3.14 4.1.2 4.2.0 latest
	./build-php.sh fpm 7.3 3.14 4.1.2 4.2.0
	./build-php.sh fpm 7.3 3.13 3.4.5 3.4.2
	./build-php.sh fpm 7.2 3.12 3.4.5 3.4.2
	./build-php.sh fpm 7.1 3.10 3.4.5 3.4.2

push-fpm: BUILDINGIMAGE=fpm
push-fpm:
	cat ./tmp/build-${BUILDINGIMAGE}.tags | xargs -I % docker push %

test-fpm: ./tmp/build-fpm.tags
	xargs -I % ./test-fpm.sh % < ./tmp/build-fpm.tags

#############################################################################################
# Clean all tags of the BUILDINGIMAGE
#############################################################################################
.NOTPARALLEL: clean-tags
clean-tags:
	rm ${current_dir}/tmp/build-${BUILDINGIMAGE}.tags || true

#############################################################################################
# CI dependencies
#############################################################################################
# Docker Hub Login
###########################################
ci-docker-login:
	docker login --username $$CONTAINER_REGISTRY_USERNAME --password $$CONTAINER_REGISTRY_PASSWORD docker.io

###########################################
# LINT
###########################################
lint:
	docker run -v ${current_dir}:/project:ro --workdir=/project --rm -it hadolint/hadolint:latest-debian hadolint /project/docker/cli.Dockerfile /project/docker/fpm.Dockerfile

lint-shell:
	docker run --rm -v ${current_dir}:/mnt:ro koalaman/shellcheck src/php/utils/install-* src/php/utils/docker/* build* test-*

###########################################
# Test
###########################################
test: test-cli test-fpm

#############################################################################################
#
#############################################################################################
scan-vulnerability:
	docker-compose -f test/security/docker-compose.yml -p clair-ci up -d
	RETRIES=0 && while ! wget -T 10 -q -O /dev/null http://localhost:6060/v1/namespaces ; do sleep 1 ; echo -n "." ; if [ $${RETRIES} -eq 10 ] ; then echo " Timeout, aborting." ; exit 1 ; fi ; RETRIES=$$(($${RETRIES}+1)) ; done
	mkdir -p ./tmp/clair/token27
	cat ./tmp/build-*.tags | xargs -I % sh -c 'clair-scanner --ip 172.17.0.1 -r "./tmp/clair/%.json" -l ./tmp/clair/clair.log % || echo "% is vulnerable"'
	docker-compose -f test/security/docker-compose.yml -p clair-ci down