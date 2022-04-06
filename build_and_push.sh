#!/bin/bash
set -e

# idea from: https://stackoverflow.com/a/50945459
function docker_tag_exists() {
    curl --silent -f -lSL https://hub.docker.com/v2/repositories/$1/tags/$2 > /dev/null 2>&1
}

IMAGE=shardlabs/cairo-cli
VERSIONS_FILE=versions.txt

curl https://pypi.org/pypi/cairo-lang/json | jq ".releases | keys" | sed -nr "s/^ *\"(.*)\".*/\1/p" > $VERSIONS_FILE

docker login --username $DOCKER_USER --password $DOCKER_PASS
while read version; do
    if [ -z $version ]; then
        continue
    fi

    echo "Version: $version"

    if docker_tag_exists $IMAGE $version ; then
        printf "Skipping\n\n"
        continue
    fi

    REQUIREMENTS_URL="https://raw.githubusercontent.com/starkware-libs/cairo-lang/v$version/scripts/requirements.txt"
    wget "$REQUIREMENTS_URL" -O requirements.txt

    TAGGED_IMAGE=$IMAGE:$version
    docker build -t $TAGGED_IMAGE --build-arg CAIRO_VERSION=$version .
    docker push $TAGGED_IMAGE
done < $VERSIONS_FILE

LATEST=$(tail -n 1 $VERSIONS_FILE)
if [[ "$(docker images -q $IMAGE:$LATEST 2> /dev/null)" == "" ]]; then
    echo "The latest image ($LATEST) is already tagged with 'latest'"
else
    docker tag $IMAGE:$LATEST $IMAGE:latest
    docker push $IMAGE:latest
fi
