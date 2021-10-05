## Idea
- This is a repository for building and pushing Docker images required by Cairo tools.
- The images are intended to be used in environments where Docker is easily applicable and Python (especially venvs) is not.
- One example of such an environment are Node.js projects, more specifically - [Hardhat](https://github.com/nomiclabs/hardhat) projects, where these images can be used by [Hardhat Docker plugin](https://www.npmjs.com/package/@nomiclabs/hardhat-docker).

## Versions
- Image names are of the form: `shardlabs/cairo-cli:<TAG>`.
- An image is built for each version, with `TAG` being the version in the semver format (e.g. for version `0.4.2` the image is `shardlabs/cairo-cli:0.4.2`).
- [The Docker Hub list of versions/tags](https://hub.docker.com/repository/registry-1.docker.io/shardlabs/cairo-cli/tags) is generally up-to-date with [the official Cairo pypi repo](https://pypi.org/pypi/cairo-lang/json).
- The latest version is also tagged with `latest`.

## Usage
Practically anything available with `cairo-compile`, `starknet-compile` and `starknet` commands (as specified [here]()) is also available through these images.

Here are a few usage examples (also try [Docker volume](https://docs.docker.com/storage/volumes/) instead of [Docker bind mount](https://docs.docker.com/storage/bind-mounts/)):

### Pull and check
```
$ docker pull shardlabs/cairo-cli:0.4.2

$ docker run shardlabs/cairo-cli:0.4.2 cairo-compile -v
cairo-compile 0.4.2 

$ docker run shardlabs/cairo-cli:0.4.2 starknet -v
starknet 0.4.2
```

### Cairo compiler
```
$ docker run \
    --mount type=bind,source=/my/project/contracts/,target=/app/contracts/ \
    shardlabs/cairo-cli:0.4.2 \
    cairo-compile contracts/test.cairo
{
    "builtins": [],
    "data": [
        ...
    ],
    "debug_info": ...
    ...
}
```

### Starknet compiler
```
$ docker run \
    --mount type=bind,source=/my/project/contracts/,target=/app/contracts/ \
    shardlabs/cairo-cli:0.4.2 \
    starknet-compile contracts/test.cairo
{
    "abi": [],
    "entry_points_by_type": {
        ...
    },
    ...
}
```
