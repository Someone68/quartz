#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel)"
VER="${1:-$(tr -d '[:space:]' < "$ROOT/VERSION")}"
OUT="$ROOT/dist/quartz-$VER-linux-x64"

echo "Building version: $VER"

# Create dist/ before the first container touches it. The daemon build runs
# as root, so on a fresh clone it would create a root-owned dist/ and the
# host-side mkdir of dist/ui-build below would then fail.
mkdir -p "$ROOT/dist"

echo "$ROOT"
ls "$ROOT/backend/requirements.txt"

echo "Building daemon/bg service"
docker run --rm -v "$ROOT:/src" -w /src \
  quartz-daemon-build bash -euc '
    python3 -m venv /tmp/venv
    /tmp/venv/bin/pip install -q -r backend/requirements.txt pyinstaller
    /tmp/venv/bin/pyinstaller packaging/quartzd.spec \
      --distpath /tmp/out \
      --workpath /tmp/work -y
    /tmp/venv/bin/python packaging/gen_icon.py /tmp/out/quartz-256.png 256 packaging/icon.png
    mkdir -p dist/daemon && cp /tmp/out/quartzd /tmp/out/quartz-256.png dist/daemon/
    chown -R '"$(id -u):$(id -g)"' dist/daemon
  '

echo "Building UI"
mkdir -p "$ROOT/dist/ui-build"
docker run --rm -v "$ROOT:/src" \
  -v "$ROOT/dist/ui-build:/src/ui/build" \
  -w /src \
  --user "$(id -u):$(id -g)" \
  quartz-ui-build bash -euc '
    export PATH=/home/builder/flutter/bin:$PATH
    git config --global --add safe.directory /src
    # material_symbols_icons drives IconData from non-constant values, which
    # the icon tree-shaker rejects; --no-tree-shake-icons keeps the full font.
    cd ui && flutter build linux --release --no-tree-shake-icons
  '

echo "Creating release archive"
rm -rf "$OUT" && mkdir -p "$OUT"

cp "$ROOT/dist/daemon/quartzd" "$OUT/"
cp "$ROOT/dist/daemon/quartz-256.png" "$OUT/"
cp -r "$ROOT/dist/ui-build/linux/x64/release/bundle" "$OUT/ui"
cp "$ROOT/packaging/linux/install.sh"    "$OUT/"
cp "$ROOT/packaging/linux/uninstall.sh"  "$OUT/"
cp "$ROOT/packaging/linux/quartz.desktop" "$OUT/"
cp "$ROOT/packaging/linux/quartzd.service" "$OUT/"
cp "$ROOT/LICENSE" "$OUT/"

chmod 755 "$OUT/install.sh" "$OUT/uninstall.sh" "$OUT/quartzd" "$OUT/ui/quartz"

tar -C "$ROOT/dist" -czf "$ROOT/dist/quartz-$VER-linux-x64.tar.gz" "quartz-$VER-linux-x64"


echo "glibc requirement check"
need_glibc=2.28
have_glibc="$(ldd --version | sed -n '1s/.*[^0-9]\([0-9]\+\.[0-9]\+\)$/\1/p')"
if [ "$(printf '%s\n%s' "$need_glibc" "$have_glibc" | sort -V | head -1)" != "$need_glibc" ]; then
  echo "glibc $need_glibc+ required, found $have_glibc" >&2
  exit 1
fi

echo "Build complete: dist/quartz-$VER-linux-x64.tar.gz"
