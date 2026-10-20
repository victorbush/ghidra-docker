# ghidra-docker

Builds the official [Ghidra Docker image](https://github.com/NationalSecurityAgency/ghidra/tree/master/docker)
from a published Ghidra release and publishes it to Docker Hub as
[`victorbush/ghidra`](https://hub.docker.com/r/victorbush/ghidra).

## How it works

- `build.sh` sets the Ghidra version and the URL of its release zip at the top. It downloads and extracts the zip.
- Publishing a GitHub release runs the **Publish Docker image** workflow. It runs
  `build.sh --download-only`, builds the release's `docker/Dockerfile`, pushes the
  image to Docker Hub and adds a build provenance attestation.

The workflow needs the repository secrets `DOCKER_USERNAME` and `DOCKER_PASSWORD`
(a Docker Hub [access token](https://docs.docker.com/security/for-developers/access-tokens/)
with read and write access).

## Tags

- `<version>` (e.g. `12.1.4`)
- `latest`, unless the GitHub release is marked as a pre-release

## Publishing

1. Set `GHIDRA_VERSION` and `GHIDRA_URL` in `build.sh` and merge to `main`.
2. Create a GitHub release from `main` whose tag is the Ghidra version (e.g. `12.1.4`).
   The workflow fails if the release tag doesn't match the version in `build.sh`.

## Building locally

Requires `bash`, `curl`, `unzip` and `docker`.

```sh
./build.sh
```

This runs the release's own `docker/build-docker-image.sh` and tags the image
`ghidra:<version>`. Set `IMAGE_NAME` to use a different repository name. Nothing is pushed.

## Usage

```sh
docker run --rm --env MODE=headless \
    --volume /path/to/myproject:/home/ghidra/myproject \
    --volume /path/to/mybinary:/home/ghidra/mybinary \
    victorbush/ghidra:latest \
    /home/ghidra/myproject programFolder -import /home/ghidra/mybinary
```

See the [upstream docs](https://github.com/NationalSecurityAgency/ghidra/blob/master/docker/README.md)
for the other modes (`gui`, `ghidra-server`, `bsim`, `bsim-server`, `pyghidra`).

## Verifying the image

```sh
gh attestation verify oci://index.docker.io/victorbush/ghidra:latest --owner victorbush
```
