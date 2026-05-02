#!/usr/bin/env bash
set -euo pipefail

vmz_artifact="${1:-ContainerPeek.vmz}"
zip_artifact="${2:-${vmz_artifact%.vmz}.zip}"
repo_root="$PWD"

case "$vmz_artifact" in
	/*) vmz_path="$vmz_artifact" ;;
	*) vmz_path="$repo_root/$vmz_artifact" ;;
esac

case "$zip_artifact" in
	/*) zip_path="$zip_artifact" ;;
	*) zip_path="$repo_root/$zip_artifact" ;;
esac

staging_dir="$(mktemp -d)"
trap 'rm -rf "$staging_dir"' EXIT

cp mod.txt "$staging_dir/mod.txt"
cp LICENSE "$staging_dir/ContainerPeek_LICENSE"
cp NOTICE "$staging_dir/ContainerPeek_NOTICE"
cp -R ContainerPeek "$staging_dir/ContainerPeek"

rm -f "$vmz_path" "$zip_path"
(
	cd "$staging_dir"
	zip -qr "$vmz_path" mod.txt ContainerPeek ContainerPeek_LICENSE ContainerPeek_NOTICE
)
zip -j "$zip_path" "$vmz_path" >/dev/null

echo "Built $vmz_artifact"
echo "Built $zip_artifact"
