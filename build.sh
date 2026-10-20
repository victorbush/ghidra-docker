#!/usr/bin/env bash
# Download the Ghidra release configured in ghidra.env and build its Docker
# image using the release's own docker/build-docker-image.sh.
#
# Usage: ./build.sh
#
# Environment:
#   IMAGE_NAME  Image repository to tag the result with (default: ghidra)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ghidra.env
source "$REPO_DIR/ghidra.env"

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

# The upstream script tags the image as ghidra/ghidra:<version>_<release name>
release_name="$(sed -n 's/^application\.release\.name=//p' "$ghidra_dir/Ghidra/application.properties")"
upstream_image="ghidra/ghidra:${GHIDRA_VERSION}_${release_name}"

bash "$ghidra_dir/docker/build-docker-image.sh"

# The upstream script doesn't reliably report build failures, so check the image exists
docker image inspect "$upstream_image" > /dev/null

for tag in "$IMAGE_TAG" latest; do
	docker tag "$upstream_image" "$IMAGE_NAME:$tag"
	echo "Tagged $IMAGE_NAME:$tag"
done

if [ -n "${GITHUB_OUTPUT:-}" ]; then
	echo "tag=$IMAGE_TAG" >> "$GITHUB_OUTPUT"
fi
