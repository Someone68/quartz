# Uninstalling

## Windows

To uninstall Quartz on Windows, run the "Uninstall Quartz" shortcut from the Start menu or the desktop.

## Linux

### With a package manager

If you installed using the .deb or .rpm package manager, you can uninstall Quartz using the package manager:

```bash
sudo apt remove quartz  # for .deb
sudo dnf remove quartz  # for .rpm
# you can also use --purge to remove config files
```

### With the script

You can uninstall Quartz on Linux using the uninstall script which is usually located in the path below:

```bash
bash ~/.local/lib/quartz/uninstall.sh
```

Otherwise, you can also run the uninstall script directly from the source directory:

```bash
# cd into the source directory first (may need to re-clone if you deleted it)
cd quartz
bash ./packaging/linux/uninstall-from-source.sh
```

### Manual

You can uninstall Quartz on Linux manually by running these commands:

```bash
# disable and remove the systemd service
systemctl --user disable --now quartzd
rm -f ~/.config/systemd/user/quartzd.service
systemctl --user daemon-reload

# remove the quartz binary and related files
rm -rf ~/.local/lib/quartz
rm -f ~/.local/bin/quartz
rm -f ~/.local/share/applications/quartz.desktop
rm -f ~/.local/share/icons/hicolor/256x256/apps/quartz.png

# update the desktop database cache
update-desktop-database ~/.local/share/applications 2>/dev/null || true
```
