# ghidra-docker

Builds the official [Ghidra Docker image](https://github.com/NationalSecurityAgency/ghidra/tree/master/docker)
from a published Ghidra release and publishes it to `ghcr.io/victorbush/ghidra`.

## How it works

1. `build.sh` sets the Ghidra version and the URL of its release zip at the top.
2. It downloads and extracts the zip, then runs the release's own
   `docker/build-docker-image.sh`.
3. The **Build and publish** workflow (run manually from the Actions tab, on `main`
   only) runs `build.sh`, pushes the image to GHCR and adds a build provenance attestation.

## Tags

- `<version>` (e.g. `12.1.4`), or `<version>_<revision>` (e.g. `12.1.4_1`) when
  `IMAGE_REVISION` is set in `build.sh`
- `latest`

## Updating Ghidra

Set `GHIDRA_VERSION` and `GHIDRA_URL` in `build.sh`, clear `IMAGE_REVISION`, merge to
`main`, then run the workflow.

To republish the same version (e.g. after fixing a build problem), set `IMAGE_REVISION`
to `1`, or to one more than the last revision, and run the workflow again.

## Building locally

Requires `bash`, `curl`, `unzip` and `docker`.

```sh
./build.sh
```

The image is tagged `ghidra:<tag>` and `ghidra:latest`. Set `IMAGE_NAME` to use a
different repository name. Nothing is pushed.

## Usage

```sh
docker run --rm --env MODE=headless \
    --volume /path/to/myproject:/home/ghidra/myproject \
    --volume /path/to/mybinary:/home/ghidra/mybinary \
    ghcr.io/victorbush/ghidra:latest \
    /home/ghidra/myproject programFolder -import /home/ghidra/mybinary
```

See the [upstream docs](https://github.com/NationalSecurityAgency/ghidra/blob/master/docker/README.md)
for the other modes (`gui`, `ghidra-server`, `bsim`, `bsim-server`, `pyghidra`).

## Verifying the image

```sh
gh attestation verify oci://ghcr.io/victorbush/ghidra:latest --owner victorbush
```
