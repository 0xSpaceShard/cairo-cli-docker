## Idea

- This is a repository for building and pushing Docker images required by Cairo tools.
- The images are intended to be used in environments where Docker is easily applicable and Python (especially venvs) is not.
- One example of such an environment are Node.js projects, more specifically - [Hardhat](https://github.com/nomiclabs/hardhat) projects, where these images can be used by [Hardhat Docker plugin](https://www.npmjs.com/package/@nomiclabs/hardhat-docker).

## Versions

- Images built using the linux/amd64 architecture have names: `shardlabs/cairo-cli:<TAG>`.
- Images built using the linux/arm64 architecture have names: `shardlabs/cairo-cli:<TAG>-arm`
- An image has been built for each cairo-lang version, with `TAG` being the version in the semver format (e.g. for version `0.11.2` the image is `shardlabs/cairo-cli:0.11.2`).
- [The Docker Hub list of versions/tags](https://hub.docker.com/repository/registry-1.docker.io/shardlabs/cairo-cli/tags) is generally up-to-date with [the official Cairo pypi repo](https://pypi.org/pypi/cairo-lang/json).
- The latest version is also tagged with `latest`.

## Preinstalled packages

Since cairo-cli:0.8.1, images come with `openzeppelin-cairo-contracts` Python package preinstalled.

## Usage

Practically anything available with `cairo-compile`, `starknet-compile-deprecated` and `starknet` commands (as specified [here](https://www.cairo-lang.org/docs/hello_starknet/index.html)) is also available through these images.

Here are a few usage examples (These rely on [Docker bind mount](https://docs.docker.com/storage/bind-mounts/); try [Docker volume](https://docs.docker.com/storage/volumes/) instead):

### Pull and check

```
$ docker pull shardlabs/cairo-cli:0.11.2

$ docker run shardlabs/cairo-cli:0.11.2 cairo-compile -v
cairo-compile 0.11.2

$ docker run shardlabs/cairo-cli:0.11.2 starknet -v
starknet 0.11.2
```

### Cairo compiler (deprecated Cairo 0)

```
$ docker run \
    --mount type=bind,source=/my/project/contracts/,target=/contracts/ \
    shardlabs/cairo-cli:0.11.2 \
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

### Starknet compiler (deprecated Cairo 0)

```
$ docker run \
    --mount type=bind,source=/my/project/contracts/,target=/contracts/ \
    shardlabs/cairo-cli:0.11.2 \
    starknet-compile-deprecated contracts/test.cairo
{
    "abi": [],
    "entry_points_by_type": {
        ...
    },
    ...
}
```

### Starknet compile (Cairo 1)

```
$ docker run \
    --mount ... \
    shardlabs/cairo-cli:0.11.2 \
    /usr/local/bin/target/release/starknet-compile
```

### Starknet Sierra compile (Cairo 1)

```
$ docker run \
    --mount ... \
    shardlabs/cairo-cli:0.11.2 \
    /usr/local/bin/target/release/starknet-sierra-compile
```

### Scarb

```
$ docker run \
    --mount ... \
    shardlabs/cairo-cli:0.11.2 \
    /usr/local/bin/scarb
```

## Build a new image

To build a new version (typically when a new cairo-lang version is released), update the `CAIRO_VERSION` in `config.yml` and create a commit on the `master` branch. Building a new image will also tag it with `latest`. Preferably also update version references in `README.md`. If needed, also update other versions in `config.yml`.

To add new commits to the repo without building, add `[skip ci]` to the commit message.
