#!/bin/bash
set -e

# idea from: https://stackoverflow.com/a/50945459
# returns "yes" or "no" instead of exit code so as to be able to use the benefits of `set -e`
function docker_tag_exists() {
    curl --silent -f -lSL https://hub.docker.com/v2/repositories/$1/tags/$2 > /dev/null 2>&1 && echo "yes" || echo "no"
}

IMAGE=shardlabs/cairo-cli
VERSIONS_FILE=versions.txt

curl https://pypi.org/pypi/cairo-lang/json | jq .releases | jq keys | sed -nr "s/^ *\"(.*)\".*/\1/p" > $VERSIONS_FILE

docker login --username $DOCKER_USER --password $DOCKER_PASS
while read VERSION; do
    if [ -z $VERSION ]; then
        continue
    fi

    echo "Version: $VERSION"

    if [ $(docker_tag_exists $IMAGE $VERSION) = "yes" ]; then
        echo "Skipping"
        echo
        continue
    fi

    REQUIREMENTS_URL="https://raw.githubusercontent.com/starkware-libs/cairo-lang/v$VERSION/scripts/requirements.txt"
    wget "$REQUIREMENTS_URL" -O requirements.txt

    TAGGED_IMAGE=$IMAGE:$VERSION
    docker build -t $TAGGED_IMAGE --build-arg CAIRO_VERSION=$VERSION .
    docker push $TAGGED_IMAGE
done < $VERSIONS_FILE

LATEST=$(tail -n 1 $VERSIONS_FILE)
if [[ "$(docker images -q $IMAGE:$LATEST 2> /dev/null)" == "" ]]; then
    echo "The latest image ($LATEST) is already tagged with 'latest'"
else
    docker tag $IMAGE:$LATEST $IMAGE:latest
    docker push $IMAGE:latest
fi
