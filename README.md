# ghidra-docker

Builds the official [Ghidra Docker image](https://github.com/NationalSecurityAgency/ghidra/tree/master/docker)
from a published Ghidra release and publishes it to the GitHub Container Registry.

## How it works

1. `ghidra.env` pins the Ghidra version (e.g. `GHIDRA_VERSION=12.1.4`).
2. `build.sh` looks up the release for tag `Ghidra_<version>_build`, downloads the
   release zip (`ghidra_<version>_PUBLIC_<date>.zip`, not the source archive), checks
   it against the sha256 digest GitHub records for it, extracts it, and runs the
   release's own `docker/build-docker-image.sh`.
3. The GitHub Actions workflow runs `build.sh` and pushes the image to
   `ghcr.io/victorbush/ghidra-docker`, along with a build provenance attestation.

## Updating Ghidra

Change `GHIDRA_VERSION` in `ghidra.env` and push to `main`. The workflow pushes these tags:

- `<version>` (e.g. `12.1.4`)
- `<version>_<release name>` (e.g. `12.1.4_PUBLIC`, which matches the upstream script's tag)
- `latest`

To build another version without changing the config, run the workflow manually
and enter a version. Manual runs with a version don't move `latest`.

Pull requests build the image without pushing it.

## Building locally

Requires `bash`, `curl`, `jq`, `unzip` and `docker`.

```sh
./build.sh            # version from ghidra.env
./build.sh 12.1.3     # specific version
```

The image is tagged `ghidra/ghidra:<version>` by default. Set `IMAGE_NAME` to change
the repository name. Set `GH_TOKEN` if you hit GitHub API rate limits. Downloads are
extracted under `work/`.

## Usage

```sh
docker run --rm --env MODE=headless \
    --volume /path/to/myproject:/home/ghidra/myproject \
    --volume /path/to/mybinary:/home/ghidra/mybinary \
    ghcr.io/victorbush/ghidra-docker:latest \
    /home/ghidra/myproject programFolder -import /home/ghidra/mybinary
```

See the [upstream docs](https://github.com/NationalSecurityAgency/ghidra/blob/master/docker/README.md)
for the other modes (`gui`, `ghidra-server`, `bsim`, `bsim-server`, `pyghidra`).

## Verifying the image

```sh
gh attestation verify oci://ghcr.io/victorbush/ghidra-docker:latest --owner victorbush
```
