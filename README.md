# ghidra-docker

Builds the official [Ghidra Docker image](https://github.com/NationalSecurityAgency/ghidra/tree/master/docker)
from a published Ghidra release and publishes it to Docker Hub as
[`victorbush/ghidra`](https://hub.docker.com/r/victorbush/ghidra).

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

## How it works

Publishing a GitHub release runs the **Publish Docker image** workflow
(`.github/workflows/build.yml`). It downloads the Ghidra release zip set in
`GHIDRA_URL` at the top of the workflow, builds the release's own `docker/Dockerfile`,
pushes the image to Docker Hub and adds a build provenance attestation.

## Publishing

1. Set `GHIDRA_URL` in the workflow and merge to `main`.
2. Create a GitHub release from `main` whose tag is the image tag (e.g. `12.1.4_PUBLIC`).
   The workflow fails if the release tag doesn't match the image tag.

## Verifying the image

```sh
gh attestation verify oci://index.docker.io/victorbush/ghidra:latest --owner victorbush
```
