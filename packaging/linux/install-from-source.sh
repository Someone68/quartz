#!/usr/bin/env bash
# User-scoped build + install with no root, for distros the .deb/.rpm don't
# cover. Everything lands under ~/.local and the daemon runs as a systemd user
# service with linger, exactly like the packaged install.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PREFIX="$HOME/.local"
APPDIR="$PREFIX/lib/quartz"

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing: $1" >&2; exit 1; }; }
need python3
need flutter

echo "==> Building daemon (PyInstaller)"
VENV="$ROOT/backend/.venv"
[ -d "$VENV" ] || python3 -m venv "$VENV"
"$VENV/bin/pip" install -q --upgrade pip
"$VENV/bin/pip" install -q -r "$ROOT/backend/requirements.txt" pyinstaller
"$VENV/bin/pyinstaller" "$ROOT/packaging/quartzd.spec" \
    --distpath "$ROOT/dist" --workpath "$ROOT/build/pyinstaller" -y

echo "==> Building UI (Flutter)"
( cd "$ROOT/ui" && flutter build linux --release )

echo "==> Installing to $APPDIR"
mkdir -p "$APPDIR" "$PREFIX/bin" \
         "$HOME/.config/systemd/user" \
         "$PREFIX/share/applications" \
         "$PREFIX/share/icons/hicolor/256x256/apps"

install -m755 "$ROOT/dist/quartzd" "$APPDIR/quartzd"
rm -rf "$APPDIR/ui"
cp -r "$ROOT/ui/build/linux/x64/release/bundle" "$APPDIR/ui"
ln -sf "$APPDIR/ui/quartz" "$PREFIX/bin/quartz"

"$VENV/bin/python" "$ROOT/packaging/gen_icon.py" \
    "$PREFIX/share/icons/hicolor/256x256/apps/quartz.png" 256

# Desktop entry pointing at the user-local launcher.
sed "s#^Exec=.*#Exec=$PREFIX/bin/quartz#" "$ROOT/packaging/linux/quartz.desktop" \
    > "$PREFIX/share/applications/quartz.desktop"

# User unit with the ExecStart pointing at the user-local daemon.
cat > "$HOME/.config/systemd/user/quartzd.service" <<EOF
[Unit]
Description=Quartz automation backend
After=graphical-session.target

[Service]
Type=simple
ExecStart=$APPDIR/quartzd
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
EOF

echo "==> Enabling service (with linger)"
loginctl enable-linger "$USER" || true
systemctl --user daemon-reload
systemctl --user enable --now quartzd

echo "Done. UI: 'quartz' or your app menu. Daemon: systemctl --user status quartzd"
