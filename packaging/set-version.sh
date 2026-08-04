#!/usr/bin/env bash
# Stamp the version from the repo-root VERSION file across every artifact so
# the daemon, UI, Linux packages and MSIX all report the same number.
#
# Usage: packaging/set-version.sh [new-version]
#   With an argument, VERSION is rewritten to it first; otherwise the current
#   VERSION file is used as the source of truth.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -ge 1 ]]; then
  echo "$1" > "$ROOT/VERSION"
fi

VER="$(tr -d '[:space:]' < "$ROOT/VERSION")"
[[ "$VER" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "VERSION must be X.Y.Z, got '$VER'" >&2
  exit 1
}

# Backend: __version__ = "X.Y.Z"
sed -i -E "s/^__version__ = \".*\"/__version__ = \"$VER\"/" \
  "$ROOT/backend/version.py"

# Flutter: version: X.Y.Z+build  (keep/refresh build number at 1)
sed -i -E "s/^version: .*/version: $VER+1/" "$ROOT/ui/pubspec.yaml"

# MSIX identity wants a 4-part version; msix_config lives in pubspec.
if grep -q "msix_version:" "$ROOT/ui/pubspec.yaml"; then
  sed -i -E "s/^  msix_version: .*/  msix_version: $VER.0/" "$ROOT/ui/pubspec.yaml"
fi

# nfpm package version.
if [[ -f "$ROOT/packaging/linux/nfpm.yaml" ]]; then
  sed -i -E "s/^version: .*/version: \"$VER\"/" "$ROOT/packaging/linux/nfpm.yaml"
fi

# MSIX manifest identity: 4-part Version="X.Y.Z.0". Anchor to the Identity line
# (whitespace then Version=) so we don't clobber MinVersion/MaxVersionTested.
MANIFEST="$ROOT/packaging/windows/AppxManifest.xml"
if [[ -f "$MANIFEST" ]]; then
  sed -i -E "s/^([[:space:]]*)Version=\"[0-9.]+\"/\1Version=\"$VER.0\"/" \
    "$MANIFEST"
fi

echo "Stamped version $VER"
