#!/bin/bash

set -eEuo pipefail

export DOCKER_BUILDKIT=1

declare -r IMAGE=$1

declare -r VERSION_PHP=$2

declare -r VERSION_ALPINE=$3

declare -r VERSION_PHALCON=$4

declare -r PHALCON_DEVTOOLS_VERSION=$5

# I could create a placeholder like php:x.y-image-alpinex.y in the Dockerfile itself,
# but I think it wouldn't be a good experience if you try to build the image yourself
# thus that's the way I opted to have dynamic base images
declare -r IMAGE_ORIGINAL_TAG="7.[0-9]-${IMAGE}-alpine3.[0-9]"

declare -r IMAGE_TAG="${VERSION_PHP}-${IMAGE}-alpine${VERSION_ALPINE}"
declare -r TOKEN27_TAG_PREFIX="token27/php-phalcon"
declare -r TOKEN27_TAG="${TOKEN27_TAG_PREFIX}:${IMAGE}-${VERSION_PHP}-phalcon-${VERSION_PHALCON}"
declare -r TOKEN27_TAG_DEV="${TOKEN27_TAG}-dev"

declare -r TAG_FILE="./tmp/build-${IMAGE}.tags"
touch "$TAG_FILE"

echo Phalcon Version: "${VERSION_PHALCON}"
echo Phalcon DevTools Version: "${PHALCON_DEVTOOLS_VERSION}"
sed -E "s/${IMAGE_ORIGINAL_TAG}/${IMAGE_TAG}/g" "./docker/${IMAGE}.Dockerfile" | docker build --pull -t "${TOKEN27_TAG}" --build-arg version_phalcon="${VERSION_PHALCON}" --build-arg version_phalcon_devtools="${PHALCON_DEVTOOLS_VERSION}" --target="${IMAGE}" -f - . &&
  echo "$TOKEN27_TAG" >>"$TAG_FILE"

sed -E "s/${IMAGE_ORIGINAL_TAG}/${IMAGE_TAG}/g" "./docker/${IMAGE}.Dockerfile" | docker build --pull -t "${TOKEN27_TAG_DEV}" --build-arg version_phalcon="${VERSION_PHALCON}" --build-arg version_phalcon_devtools="${PHALCON_DEVTOOLS_VERSION}" --target="${IMAGE}-dev" -f - . &&
  echo "$TOKEN27_TAG_DEV" >>"$TAG_FILE"

for IMAGE_EXTRA_TAG in "${@:6}"; do
  declare NEW_TAG="${TOKEN27_TAG_PREFIX}:${IMAGE}-${IMAGE_EXTRA_TAG}"
  docker tag "${TOKEN27_TAG}" "${NEW_TAG}" && echo "${NEW_TAG}" >>"${TAG_FILE}"
  docker tag "${TOKEN27_TAG_DEV}" "${NEW_TAG}-dev" && echo "${NEW_TAG}-dev" >>"${TAG_FILE}"
done
