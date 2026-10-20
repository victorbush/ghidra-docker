#!/usr/bin/env bash
# Download a Ghidra release from GitHub and build its Docker image using the
# release's own docker/build-docker-image.sh.
#
# Usage: ./build.sh [version]
#   version     Ghidra version (e.g. 12.1.4). Defaults to GHIDRA_VERSION in ghidra.env.
#
# Environment:
#   IMAGE_NAME  Image repository to tag the result with (default: ghidra/ghidra)
#   GH_TOKEN    Optional GitHub token, used to avoid API rate limits
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ghidra.env
source "$REPO_DIR/ghidra.env"

VERSION="${1:-$GHIDRA_VERSION}"
IMAGE_NAME="${IMAGE_NAME:-ghidra/ghidra}"
TAG="Ghidra_${VERSION}_build"
WORK_DIR="$REPO_DIR/work/$VERSION"

for cmd in curl jq unzip docker sha256sum; do
	command -v "$cmd" > /dev/null || { echo "ERROR: $cmd is required" >&2; exit 1; }
done

auth=()
if [ -n "${GH_TOKEN:-}" ]; then
	auth=(-H "Authorization: Bearer $GH_TOKEN")
fi

# Find the release zip (not the source code archive) for the tag
echo "Looking up release $TAG"
release_json="$(curl -fsSL "${auth[@]}" -H "Accept: application/vnd.github+json" \
	"https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/tags/$TAG")"
asset="$(jq -c '[.assets[] | select(.name | test("^ghidra_.*_PUBLIC_.*\\.zip$"))][0] // empty' <<< "$release_json")"
if [ -z "$asset" ]; then
	echo "ERROR: no ghidra_*_PUBLIC_*.zip asset found in release $TAG" >&2
	exit 1
fi
asset_name="$(jq -r .name <<< "$asset")"
asset_url="$(jq -r .browser_download_url <<< "$asset")"
asset_digest="$(jq -r '.digest // empty' <<< "$asset")"

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

echo "Downloading $asset_name"
curl -fL --retry 3 -o "$WORK_DIR/$asset_name" "$asset_url"

if [[ "$asset_digest" == sha256:* ]]; then
	echo "${asset_digest#sha256:}  $WORK_DIR/$asset_name" | sha256sum -c -
else
	echo "WARNING: release has no sha256 digest for $asset_name; skipping verification"
fi

echo "Extracting $asset_name"
unzip -q "$WORK_DIR/$asset_name" -d "$WORK_DIR"
rm "$WORK_DIR/$asset_name"

ghidra_dir="$(find "$WORK_DIR" -mindepth 1 -maxdepth 1 -type d -name 'ghidra_*' | head -n 1)"
if [ ! -f "$ghidra_dir/docker/build-docker-image.sh" ]; then
	echo "ERROR: $asset_name does not contain docker/build-docker-image.sh" >&2
	exit 1
fi

# The upstream script tags the image as ghidra/ghidra:<version>_<release name>
release_name="$(sed -n 's/^application\.release\.name=//p' "$ghidra_dir/Ghidra/application.properties")"
upstream_image="ghidra/ghidra:${VERSION}_${release_name}"

bash "$ghidra_dir/docker/build-docker-image.sh"

# The upstream script doesn't reliably report build failures, so check the image exists
docker image inspect "$upstream_image" > /dev/null

tags=("$IMAGE_NAME:$VERSION" "$IMAGE_NAME:${VERSION}_${release_name}")
for t in "${tags[@]}"; do
	[ "$t" = "$upstream_image" ] || docker tag "$upstream_image" "$t"
	echo "Tagged $t"
done

if [ -n "${GITHUB_OUTPUT:-}" ]; then
	{
		echo "version=$VERSION"
		echo "tags=${tags[*]}"
	} >> "$GITHUB_OUTPUT"
fi
