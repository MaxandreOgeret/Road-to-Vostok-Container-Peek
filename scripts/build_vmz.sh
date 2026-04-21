#!/usr/bin/env bash
set -euo pipefail

vmz_artifact="${1:-ContainerPeek.vmz}"
zip_artifact="${2:-${vmz_artifact%.vmz}.zip}"

rm -f "$vmz_artifact" "$zip_artifact"
zip -r "$vmz_artifact" mod.txt README.md DESCRIPTION.md LICENSE NOTICE ContainerPeek doc -x '*/.git/*' >/dev/null
zip -j "$zip_artifact" "$vmz_artifact" >/dev/null

echo "Built $vmz_artifact"
echo "Built $zip_artifact"
