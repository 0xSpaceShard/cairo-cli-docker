#!/bin/bash
set -eu

IMAGE=shardlabs/cairo-cli
TAG="${CAIRO_VERSION}${TAG_SUFFIX}"

docker login --username "$DOCKER_USER" --password "$DOCKER_PASS"

# get requirements
REQUIREMENTS_URL="https://raw.githubusercontent.com/starkware-libs/cairo-lang/$CAIRO_VERSION/scripts/requirements.txt"
status=$(curl -s -o /dev/null -w "%{http_code}" "$REQUIREMENTS_URL")
if [ "$status" != 200 ]; then
    echo "Error! Got status $status while fetching requirements"
    exit 1
fi
curl "$REQUIREMENTS_URL" > requirements.txt

# compiler binary download URL
COMPILER_BINARY_URL="https://github.com/starkware-libs/cairo/releases/download/$CAIRO_COMPILER_TARGET_TAG/$CAIRO_COMPILER_ASSET_NAME"
# build and tag
TAGGED_IMAGE="$IMAGE:$TAG"
LATEST_IMAGE="$IMAGE:latest$TAG_SUFFIX"
docker build \
    -t "$TAGGED_IMAGE" -t "$LATEST_IMAGE" \
    --build-arg CAIRO_VERSION="$CAIRO_VERSION" \
    --build-arg OZ_VERSION="$OZ_VERSION" \
    --build-arg COMPILER_BINARY_URL="$COMPILER_BINARY_URL" \
    --build-arg CAIRO_COMPILER_ASSET_NAME="$CAIRO_COMPILER_ASSET_NAME" \
    --build-arg SCARB_VERSION="$SCARB_VERSION" \
    .

# verify
docker run "$TAGGED_IMAGE" sh -c "starknet --version \
    && starknet-compile-deprecated --version \
    && /usr/local/bin/target/release/starknet-compile --version \
    && /usr/local/bin/target/release/starknet-sierra-compile --version"
# push
docker push "$TAGGED_IMAGE"
docker push "$LATEST_IMAGE"
