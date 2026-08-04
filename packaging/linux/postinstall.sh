#!/bin/sh
# Runs as root after the package is installed. The daemon is a *user* service
# (needs the user's session, env and permissions), so we resolve the human who
# triggered the install and enable it for them, with linger so it also runs
# before they log in — schedule triggers fire on a headless boot.
set -e

TARGET_USER="${SUDO_USER:-}"
# Fall back to the owner of an active graphical session if sudo didn't set it.
if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
    TARGET_USER="$(loginctl list-users --no-legend 2>/dev/null \
        | awk '$2 != "root" {print $2; exit}')"
fi

if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
    cat <<'EOF'
Quartz installed. Finish setup as your normal user:
    systemctl --user daemon-reload
    systemctl --user enable --now quartzd
    loginctl enable-linger "$USER"
EOF
    exit 0
fi

UID_NUM="$(id -u "$TARGET_USER")"

# Keep the daemon alive across logout/reboot.
loginctl enable-linger "$TARGET_USER" || true

# Enable + start the service in the target user's manager.
sudo -u "$TARGET_USER" \
    XDG_RUNTIME_DIR="/run/user/$UID_NUM" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID_NUM/bus" \
    sh -c 'systemctl --user daemon-reload && systemctl --user enable --now quartzd' \
    || echo "Could not auto-start quartzd; run 'systemctl --user enable --now quartzd' as $TARGET_USER."

exit 0
