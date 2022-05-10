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
> $VERSIONS_FILE


docker login --username $DOCKER_USER --password $DOCKER_PASS

# Will iterate over sorted versions and start building images when minimum version reached
if [ -z $MIN_VER ]; then
    MIN_VER_REACHED="true"
else
    MIN_VER_REACHED="false"
fi

while read version; do
    if [ -z $version ]; then
        continue
    fi

    tag="${version}${TAG_SUFFIX}"
    echo "Version: $version; Tag: $tag"

    # if at least at minimum version, proceed with building
    if [ $MIN_VER_REACHED == "false" ]; then
        if [ $version == "$MIN_VER" ]; then
            MIN_VER_REACHED="true"
        else
            printf "Minimum not reached. Skipping\n\n"
            continue
        fi
    fi

    if docker_tag_exists $IMAGE $tag ; then
        printf "Image exists. Skipping\n\n"
        continue
    fi

    REQUIREMENTS_URL="https://raw.githubusercontent.com/starkware-libs/cairo-lang/v$version/scripts/requirements.txt"
    status=$(curl -s -o /dev/null -w "%{http_code}" "$REQUIREMENTS_URL")
    if [ "$status" != 200 ]; then
        printf "Warning! Got status $status\n\n"
        continue
    fi
    curl "$REQUIREMENTS_URL" > requirements.txt

    TAGGED_IMAGE=$IMAGE:$tag
    docker build -t $TAGGED_IMAGE --build-arg CAIRO_VERSION=$version .

    # verify
    docker run $TAGGED_IMAGE starknet-compile --version
    docker run $TAGGED_IMAGE starknet --version

    docker push $TAGGED_IMAGE
done < $VERSIONS_FILE

NEWEST=$(tail -n 1 $VERSIONS_FILE)
NEWEST_TAG="${NEWEST}${TAG_SUFFIX}"
if [[ "$(docker images -q $IMAGE:$NEWEST_TAG 2> /dev/null)" == "" ]]; then
    echo "The newest version ($NEWEST_TAG) has already been pushed"
else
    LATEST_TAG="latest$TAG_SUFFIX"
    docker tag $IMAGE:$NEWEST_TAG $IMAGE:$LATEST_TAG
    docker push $IMAGE:$LATEST_TAG
fi
