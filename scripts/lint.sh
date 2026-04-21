#!/usr/bin/env bash
set -euo pipefail

if ! command -v gdlint >/dev/null 2>&1; then
	echo "gdlint is required. Install gdtoolkit first." >&2
	exit 1
fi

if ! command -v gdformat >/dev/null 2>&1; then
	echo "gdformat is required. Install gdtoolkit first." >&2
	exit 1
fi

gdlint ContainerPeek
gdformat --check ContainerPeek
