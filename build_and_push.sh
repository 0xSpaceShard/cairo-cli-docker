#!/bin/bash
set -e

# idea from: https://stackoverflow.com/a/50945459
function docker_tag_exists() {
    curl --silent -f -lSL https://hub.docker.com/v2/repositories/$1/tags/$2 > /dev/null 2>&1
}

IMAGE=shardlabs/cairo-cli
VERSIONS_FILE=versions.txt

curl https://pypi.org/pypi/cairo-lang/json \
| jq ".releases | keys" \
| sed -nr "s/^ *\"(.*)\".*/\1/p" \
| sort -t "." -k1,1n -k2,2n -k3,3n \
| tail -n 1 \
> $VERSIONS_FILE
# TODO remove tail -n 1

docker login --username $DOCKER_USER --password $DOCKER_PASS
while read version; do
    if [ -z $version ]; then
        continue
    fi

    tag="${version}${TAG_SUFFIX}"

    echo "Version: $version; Tag: $tag"

    # Checking $version instead of $tag since the introduction of -arm suffix
    # None of the 19 <VERSION>-arm tags would be present and they would all have to be rebuilt for ~4 hours
    if docker_tag_exists $IMAGE $version ; then
        printf "Skipping\n\n"
        continue
    fi

    REQUIREMENTS_URL="https://raw.githubusercontent.com/starkware-libs/cairo-lang/v$version/scripts/requirements.txt"
    curl "$REQUIREMENTS_URL" > requirements.txt

    TAGGED_IMAGE=$IMAGE:$tag
    docker build -t $TAGGED_IMAGE --build-arg CAIRO_VERSION=$version .

    # verify
    docker run $TAGGED_IMAGE starknet-compile --version
    docker run $TAGGED_IMAGE starknet --version

    docker push $TAGGED_IMAGE
done < $VERSIONS_FILE

NEWEST=$(tail -n 1 $VERSIONS_FILE)
if [[ "$(docker images -q $IMAGE:$NEWEST 2> /dev/null)" == "" ]]; then
    echo "The newest version ($NEWEST) has already been pushed"
else
    LATEST_TAG="latest$TAG_SUFFIX"
    docker tag $IMAGE:$NEWEST $IMAGE:$LATEST_TAG
    docker push $IMAGE:$LATEST_TAG
fi
