#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mods_dir="${RTV_MODS_DIR:-$HOME/.steam/debian-installation/steamapps/common/Road to Vostok/mods}"
vmz_artifact="${1:-ContainerPeek.vmz}"

cd "$repo_root"

./scripts/build_vmz.sh "$vmz_artifact"

mkdir -p "$mods_dir"
cp "$vmz_artifact" "$mods_dir/$(basename "$vmz_artifact")"

echo "Deployed $(basename "$vmz_artifact") to $mods_dir"
