"""Filesystem locations, resolved for both source runs and frozen builds."""

import sys
from pathlib import Path

IS_FROZEN = getattr(sys, "frozen", False)

# Root the action/trigger plugin dirs hang off. Under PyInstaller these are
# shipped as data files (they are loaded by path, not imported), so they live
# under sys._MEIPASS rather than next to the source.
BUNDLE_DIR = Path(getattr(sys, "_MEIPASS", Path(__file__).parent))

ACTIONS_DIR = BUNDLE_DIR / "actions"
TRIGGERS_DIR = BUNDLE_DIR / "triggers"

ICON_FILE = (
    BUNDLE_DIR / "icon.png"
    if IS_FROZEN
    else Path(__file__).resolve().parent.parent / "packaging" / "icon.png"
)
