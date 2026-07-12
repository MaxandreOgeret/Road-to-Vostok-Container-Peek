#!/usr/bin/env bash
set -euo pipefail

if ! command -v zip >/dev/null 2>&1; then
	echo "zip is required. Install zip first." >&2
	exit 1
fi

caller_cwd="$PWD"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

vmz_artifact="${1:-ContainerPeek.vmz}"
zip_artifact="${2:-${vmz_artifact%.vmz}.zip}"

case "$vmz_artifact" in
	/*) vmz_path="$vmz_artifact" ;;
	*) vmz_path="$caller_cwd/$vmz_artifact" ;;
esac

case "$zip_artifact" in
	/*) zip_path="$zip_artifact" ;;
	*) zip_path="$caller_cwd/$zip_artifact" ;;
esac

cd "$repo_root"

staging_dir="$(mktemp -d)"
trap 'rm -rf "$staging_dir"' EXIT

cp mod.txt "$staging_dir/mod.txt"
cp LICENSE "$staging_dir/ContainerPeek_LICENSE"
cp NOTICE "$staging_dir/ContainerPeek_NOTICE"
cp -R ContainerPeek "$staging_dir/ContainerPeek"
# Prune keeps find from descending into directories it just deleted.
find "$staging_dir/ContainerPeek" -mindepth 1 -name '.*' -prune -exec rm -rf {} +

rm -f "$vmz_path" "$zip_path"
(
	cd "$staging_dir"
	zip -qr "$vmz_path" mod.txt ContainerPeek ContainerPeek_LICENSE ContainerPeek_NOTICE
)
zip -j "$zip_path" "$vmz_path" >/dev/null

echo "Built $vmz_artifact"
echo "Built $zip_artifact"
