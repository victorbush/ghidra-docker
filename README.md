# ghidra-docker

Builds the official [Ghidra Docker image](https://github.com/NationalSecurityAgency/ghidra/tree/master/docker)
from a published Ghidra release and publishes it to Docker Hub as
[`victorbush/ghidra`](https://hub.docker.com/r/victorbush/ghidra).

## How it works

Publishing a GitHub release runs the **Publish Docker image** workflow
(`.github/workflows/build.yml`). It downloads the Ghidra release zip set in
`GHIDRA_URL` at the top of the workflow, builds the release's own `docker/Dockerfile`,
pushes the image to Docker Hub and adds a build provenance attestation.

The workflow needs the repository secrets `DOCKER_USERNAME` and `DOCKER_PASSWORD`
(a Docker Hub [access token](https://docs.docker.com/security/for-developers/access-tokens/)
with read and write access).

## Tags

- `<version>_<release name>` (e.g. `12.1.4_PUBLIC`), the same tag upstream's
  `docker/build-docker-image.sh` uses
- `latest`, unless the GitHub release is marked as a pre-release

## Publishing

1. Set `GHIDRA_URL` in the workflow and merge to `main`.
2. Create a GitHub release from `main` whose tag is the image tag (e.g. `12.1.4_PUBLIC`).
   The workflow fails if the release tag doesn't match the image tag.

## Building locally

Download and extract a [Ghidra release](https://github.com/NationalSecurityAgency/ghidra/releases)
and run `docker/build-docker-image.sh` from it.

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
