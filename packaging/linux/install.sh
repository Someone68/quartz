#!/usr/bin/env bash
set -euo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PREFIX="$HOME/.local"
APPDIR="$PREFIX/lib/quartz"
UNITDIR="$HOME/.config/systemd/user"

# Fail early with a useful message instead of a linker error later.
need_glibc=2.28
have_glibc="$(ldd --version | sed -n '1s/.*[^0-9]\([0-9]\+\.[0-9]\+\)$/\1/p')"
if [ "$(printf '%s\n%s' "$need_glibc" "$have_glibc" | sort -V | head -1)" != "$need_glibc" ]; then
  echo "glibc $need_glibc+ required, found $have_glibc" >&2
  echo "Build from source: ./packaging/linux/install.sh" >&2
  exit 1
fi
command -v systemctl >/dev/null || { echo "systemd required" >&2; exit 1; }

systemctl --user stop quartzd 2>/dev/null || true

echo "==> Installing to $APPDIR"
mkdir -p "$APPDIR" "$PREFIX/bin" "$UNITDIR" \
         "$PREFIX/share/applications" \
         "$PREFIX/share/icons/hicolor/256x256/apps"

install -m755 "$SRC/quartzd" "$APPDIR/quartzd"
rm -rf "$APPDIR/ui"
cp -r "$SRC/ui" "$APPDIR/ui"
chmod 755 "$APPDIR/ui/quartz"
ln -sf "$APPDIR/ui/quartz" "$PREFIX/bin/quartz"
install -m755 "$SRC/uninstall.sh" "$APPDIR/uninstall.sh"
install -m644 "$SRC/quartz-256.png" \
    "$PREFIX/share/icons/hicolor/256x256/apps/quartz.png"

sed "s#^Exec=.*#Exec=$PREFIX/bin/quartz#" "$SRC/quartz.desktop" \
    > "$PREFIX/share/applications/quartz.desktop"
sed "s#^ExecStart=.*#ExecStart=$APPDIR/quartzd#" "$SRC/quartzd.service" \
    > "$UNITDIR/quartzd.service"

command -v gtk-update-icon-cache >/dev/null \
    && gtk-update-icon-cache -qtf "$PREFIX/share/icons/hicolor" 2>/dev/null || true
command -v update-desktop-database >/dev/null \
    && update-desktop-database "$PREFIX/share/applications" 2>/dev/null || true

systemctl --user daemon-reload
systemctl --user enable --now quartzd

case ":$PATH:" in
  *":$PREFIX/bin:"*) ;;
  *) echo "WARN: $PREFIX/bin not in PATH. Add it to ~/.profile to run 'quartz'." ;;
esac

echo "Done. Uninstall: $APPDIR/uninstall.sh"
