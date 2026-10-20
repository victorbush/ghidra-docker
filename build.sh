#!/usr/bin/env bash
# Download a Ghidra release and build its Docker image using the release's own
# docker/build-docker-image.sh.
#
# Usage: ./build.sh [--download-only]
#   --download-only  Download and extract the release but don't build it. The
#                    publish workflow uses this and builds the image itself.
set -euo pipefail

# Ghidra release zip to build
GHIDRA_URL=https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_12.1.4_build/ghidra_12.1.4_PUBLIC_20260921.zip

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Same tag as upstream's build script: <version>_<release name>, e.g. 12.1.4_PUBLIC
properties="$ghidra_dir/Ghidra/application.properties"
version="$(sed -n 's/^application\.version=//p' "$properties")"
release_name="$(sed -n 's/^application\.release\.name=//p' "$properties")"
image_tag="${version}_${release_name}"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
	{
		echo "version=$version"
		echo "tag=$image_tag"
		echo "context=$ghidra_dir"
	} >> "$GITHUB_OUTPUT"
fi

if [ "${1:-}" = "--download-only" ]; then
	exit 0
fi

bash "$ghidra_dir/docker/build-docker-image.sh"

# The upstream script doesn't reliably report build failures, so check the image exists
docker image inspect "ghidra/ghidra:$image_tag" > /dev/null
