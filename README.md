## Basic
- This is a repository for building and pushing Docker images required by Cairo tools.
- Image names are of the form: `shardlabs/cairo-cli:<TAG>`.

## Versions
- Available Cairo versions are taken from [the official pypi repo](https://pypi.org/pypi/cairo-lang/json).
- An image is built for each version, with tag being the version in the semver format (e.g. `0.4.1`).
- The latest version is also tagged with `latest`.
