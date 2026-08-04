#!/bin/sh
# Runs as root before the package is removed. Stop and disable the user service
# for whoever it was enabled for so no orphaned daemon lingers.
set -e

TARGET_USER="${SUDO_USER:-}"
if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
    TARGET_USER="$(loginctl list-users --no-legend 2>/dev/null \
        | awk '$2 != "root" {print $2; exit}')"
fi

[ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ] || exit 0

UID_NUM="$(id -u "$TARGET_USER" 2>/dev/null)" || exit 0

sudo -u "$TARGET_USER" \
    XDG_RUNTIME_DIR="/run/user/$UID_NUM" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID_NUM/bus" \
    systemctl --user disable --now quartzd 2>/dev/null || true

exit 0
