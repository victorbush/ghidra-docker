#!/usr/bin/env bash
# Download a Ghidra release and build its Docker image using the release's own
# docker/build-docker-image.sh.
#
# Usage: ./build.sh [--download-only]
#   --download-only  Download and extract the release but don't build it. The
#                    publish workflow uses this and builds the image itself.
#
# Environment:
#   IMAGE_NAME  Image repository to tag the result with (default: ghidra)
set -euo pipefail

# Ghidra release to build
GHIDRA_VERSION=12.1.4
GHIDRA_URL=https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_12.1.4_build/ghidra_12.1.4_PUBLIC_20260921.zip

# Leave empty for the first publish of a version (tag: 12.1.4). To republish
# the same version, set to 1, 2, ... (tags: 12.1.4_1, 12.1.4_2, ...).
IMAGE_REVISION=

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IMAGE_NAME="${IMAGE_NAME:-ghidra}"
IMAGE_TAG="${GHIDRA_VERSION}${IMAGE_REVISION:+_$IMAGE_REVISION}"
WORK_DIR="$REPO_DIR/work"
ZIP="$WORK_DIR/$(basename "$GHIDRA_URL")"

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

echo "Downloading $GHIDRA_URL"
curl -fL --retry 3 -o "$ZIP" "$GHIDRA_URL"

echo "Extracting $ZIP"
unzip -q "$ZIP" -d "$WORK_DIR"
rm "$ZIP"

ghidra_dir="$(find "$WORK_DIR" -mindepth 1 -maxdepth 1 -type d -name 'ghidra_*' | head -n 1)"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
	{
		echo "tag=$IMAGE_TAG"
		echo "context=$ghidra_dir"
	} >> "$GITHUB_OUTPUT"
fi

if [ "${1:-}" = "--download-only" ]; then
	exit 0
fi

# The upstream script tags the image as ghidra/ghidra:<version>_<release name>
release_name="$(sed -n 's/^application\.release\.name=//p' "$ghidra_dir/Ghidra/application.properties")"
upstream_image="ghidra/ghidra:${GHIDRA_VERSION}_${release_name}"

bash "$ghidra_dir/docker/build-docker-image.sh"

# The upstream script doesn't reliably report build failures, so check the image exists
docker image inspect "$upstream_image" > /dev/null

docker tag "$upstream_image" "$IMAGE_NAME:$IMAGE_TAG"
echo "Tagged $IMAGE_NAME:$IMAGE_TAG"
