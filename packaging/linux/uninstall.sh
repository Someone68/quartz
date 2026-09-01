#!/usr/bin/env bash
set -euo pipefail
PREFIX="$HOME/.local"
APPDIR="$PREFIX/lib/quartz"

systemctl --user disable --now quartzd 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/quartzd.service"
systemctl --user daemon-reload 2>/dev/null || true

rm -rf "$APPDIR"
rm -f "$PREFIX/bin/quartz" \
      "$PREFIX/share/applications/quartz.desktop" \
      "$PREFIX/share/icons/hicolor/256x256/apps/quartz.png"

command -v update-desktop-database >/dev/null \
    && update-desktop-database "$PREFIX/share/applications" 2>/dev/null || true

echo "Quartz uninstalled. Config is still at ~/.config/quartz and ~/.local/share/quartz (delete manually if u want)"
