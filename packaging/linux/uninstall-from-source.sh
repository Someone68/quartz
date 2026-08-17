#!/usr/bin/env bash
# Reverses install-from-source.sh. Shipped to $APPDIR/uninstall.sh by the
# installer, so it can locate everything relative to its own path.
#
#   uninstall.sh            # remove the app, keep shortcuts and run history
#   uninstall.sh --purge    # also remove ~/.config/quartz
#   uninstall.sh --yes      # no confirmation prompt
set -euo pipefail

APPDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="$(dirname "$(dirname "$APPDIR")")"   # ~/.local/lib/quartz -> ~/.local
DATA_DIR="$HOME/.config/quartz"

PURGE=0
ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        --purge) PURGE=1 ;;
        --yes|-y) ASSUME_YES=1 ;;
        -h|--help) sed -n '2,7p' "${BASH_SOURCE[0]}"; exit 0 ;;
        *) echo "unknown option: $arg" >&2; exit 2 ;;
    esac
done

DESKTOP="$PREFIX/share/applications/quartz.desktop"
ICON="$PREFIX/share/icons/hicolor/256x256/apps/quartz.png"
UNIT="$HOME/.config/systemd/user/quartzd.service"
BIN="$PREFIX/bin/quartz"

echo "This will remove:"
echo "  $APPDIR"
echo "  $BIN"
echo "  $DESKTOP"
echo "  $ICON"
echo "  $UNIT"
if [ "$PURGE" = 1 ]; then
    echo "  $DATA_DIR  (shortcuts and run history)"
else
    echo "Keeping $DATA_DIR - pass --purge to remove it too."
fi

if [ "$ASSUME_YES" != 1 ]; then
    read -r -p "Continue? [y/N] " reply
    case "$reply" in [yY]|[yY][eE][sS]) ;; *) echo "Aborted."; exit 1 ;; esac
fi

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user disable --now quartzd 2>/dev/null || true
fi
rm -f "$UNIT"
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user reset-failed quartzd 2>/dev/null || true
fi

if [ -L "$BIN" ] && [ "$(readlink "$BIN")" = "$APPDIR/ui/quartz" ]; then
    rm -f "$BIN"
elif [ -e "$BIN" ]; then
    echo "Left $BIN alone: not a symlink into $APPDIR."
fi

rm -f "$DESKTOP" "$ICON"
command -v update-desktop-database >/dev/null 2>&1 \
    && update-desktop-database "$PREFIX/share/applications" 2>/dev/null || true
command -v gtk-update-icon-cache >/dev/null 2>&1 \
    && gtk-update-icon-cache -qtf "$PREFIX/share/icons/hicolor" 2>/dev/null || true

if [ "$PURGE" = 1 ]; then
    rm -rf "$DATA_DIR"
fi

if command -v loginctl >/dev/null 2>&1 \
   && [ "$(loginctl show-user "$USER" -p Linger --value 2>/dev/null)" = "yes" ]; then
    echo "Linger is still enabled for $USER. Disable with: loginctl disable-linger $USER"
fi

rm -rf "$APPDIR"
echo "Quartz removed."
