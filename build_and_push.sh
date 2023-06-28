#!/bin/bash
set -eu

IMAGE=shardlabs/cairo-cli
TAG="${CAIRO_VERSION}${TAG_SUFFIX}"

docker login --username "$DOCKER_USER" --password "$DOCKER_PASS"

# get requirements
REQUIREMENTS_URL="https://raw.githubusercontent.com/starkware-libs/cairo-lang/v$CAIRO_VERSION/scripts/requirements.txt"
status=$(curl -s -o /dev/null -w "%{http_code}" "$REQUIREMENTS_URL")
if [ "$status" != 200 ]; then
    echo "Error! Got status $status while fetching requirements"
    exit 1
fi
curl "$REQUIREMENTS_URL" > requirements.txt

# build and tag
TAGGED_IMAGE="$IMAGE:$TAG"
LATEST_IMAGE="$IMAGE:latest$TAG_SUFFIX"
docker build \
    -t "$TAGGED_IMAGE" -t "$LATEST_IMAGE" \
    --build-arg CAIRO_VERSION="$CAIRO_VERSION" \
    --build-arg OZ_VERSION="$OZ_VERSION" \
    --build-arg CAIRO_COMPILER_TARGET_TAG="$CAIRO_COMPILER_TARGET_TAG" \
    --build-arg SCARB_VERSION="$SCARB_VERSION" \
    .

# verify
# verify and assert contract compilation
cairo_0_contract="contracts/cairo0/contract.cairo"
cairo_1_contract="contracts/cairo1/contract1.cairo"

dir="$(pwd)"
cairo_1_output="$dir/artifacts/contracts/cairo1"
cairo_0_output="$dir/artifacts/contracts/cairo"

mkdir -p "$cairo_1_output"
mkdir -p "$cairo_0_output"

# compile cairo 0 contract
docker run -v "$dir":"$dir" "$TAGGED_IMAGE" \
    sh -c "starknet-compile-deprecated "$dir/$cairo_0_contract" --abi "$cairo_0_output/contract_abi.json" --output "$cairo_0_output/contract.json""

# compile cairo 1 contract
docker run -v "$dir":"$dir" "$TAGGED_IMAGE" \
    sh -c  "/usr/local/bin/target/release/starknet-compile "$dir/$cairo_1_contract" "$cairo_1_output/contract1.json" \
    && /usr/local/bin/target/release/starknet-sierra-compile "$cairo_1_output/contract1.json" "$cairo_1_output/contract1.casm""

# verify compilation
if [[ ! -f "$cairo_0_output/contract.json"  ||  ! -f "$cairo_0_output/contract_abi.json" ]]; then
    echo "One or more Cairo 0 files not found!"
    exit 1
fi

if [[ ! -f "$cairo_1_output/contract1.json" || ! -f "$cairo_1_output/contract1.casm" ]]; then
    echo "One or more Cairo 1 files not found!"
    exit 1
fi

echo "Contracts compiled successfully!"

# Check if the current branch is "master"
if [ "$CIRCLE_BRANCH" == "master" ]; then
    # Push the Docker images
    docker push "$TAGGED_IMAGE"
    docker push "$LATEST_IMAGE"
else
    echo "Skipping Docker image push."
fi
