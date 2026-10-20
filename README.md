# ghidra-docker

Builds the official [Ghidra Docker image](https://github.com/NationalSecurityAgency/ghidra/tree/master/docker)
from a published Ghidra release and publishes it to Docker Hub as
[`victorbush/ghidra`](https://hub.docker.com/r/victorbush/ghidra).

## How it works

- `build.sh` sets the Ghidra version, the URL of its release zip and the image
  revision at the top. It downloads and extracts the zip.
- Publishing a GitHub release runs the **Publish Docker image** workflow. It runs
  `build.sh --download-only`, builds the release's `docker/Dockerfile`, pushes the
  image to Docker Hub and adds a build provenance attestation.

The workflow needs the repository secrets `DOCKER_USERNAME` and `DOCKER_PASSWORD`
(a Docker Hub [access token](https://docs.docker.com/security/for-developers/access-tokens/)
with read and write access).

## Tags

- `<version>` (e.g. `12.1.4`), or `<version>_<revision>` (e.g. `12.1.4_beta1`,
  `12.1.4_1`) when `IMAGE_REVISION` is set in `build.sh`
- `latest`, unless the GitHub release is marked as a pre-release

## Publishing

1. Set `GHIDRA_VERSION`, `GHIDRA_URL` and `IMAGE_REVISION` in `build.sh` and merge to `main`.
2. Create a GitHub release from `main` whose tag is the image tag (e.g. `12.1.4_beta1`).
   Tick **Set as a pre-release** for test builds so `latest` isn't moved.
   The workflow fails if the release tag doesn't match the tag in `build.sh`.

Use `IMAGE_REVISION=beta1`, `beta2`, ... while testing, leave it empty for the real
publish of a version, and set it to `1`, `2`, ... to republish the same version.

## Building locally

Requires `bash`, `curl`, `unzip` and `docker`.

```sh
./build.sh
```

This runs the release's own `docker/build-docker-image.sh` and tags the image
`ghidra:<tag>`. Set `IMAGE_NAME` to use a different repository name. Nothing is pushed.

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
