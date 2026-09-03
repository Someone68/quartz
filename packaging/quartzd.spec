# -*- mode: python ; coding: utf-8 -*-
"""PyInstaller spec for the Quartz daemon (quartzd).

Built from the repo root, not from backend/:

    pyinstaller packaging/quartzd.spec --distpath dist --workpath build/pyinstaller -y

Produces a single-file dist/quartzd (dist/quartzd.exe on Windows), which is
what packaging/linux/nfpm.yaml and packaging/windows/build-msix.ps1 install.
"""

import sys
from pathlib import Path

from PyInstaller.utils.hooks import collect_data_files

ROOT = Path(SPECPATH).parent
BACKEND = ROOT / "backend"

IS_WINDOWS = sys.platform == "win32"
IS_LINUX = sys.platform.startswith("linux")


def plugin_datas(name):
    """Ship actions/ and triggers/ as loose .py source files.

    registry.load_all() reads these by path with importlib rather than
    importing them, so they must stay on disk as data; freezing them into the
    archive makes the daemon start with zero actions and zero triggers.

    Destinations are relative to backend/ so they land at actions/ and
    triggers/ inside sys._MEIPASS, where paths.py looks for them.
    """
    root = BACKEND / name
    return [
        (str(p), str(p.parent.relative_to(BACKEND)))
        for p in root.rglob("*.py")
        if "__pycache__" not in p.parts
    ]


# Modules nothing on the main.py import graph reaches, so Analysis cannot see
# them. dialogs and subproc are imported only by action files, which are data.
# The uvicorn and pynput submodules are selected by string at runtime.
hiddenimports = [
    "dialogs",
    "subproc",
    "uvicorn.logging",
    "uvicorn.loops.auto",
    "uvicorn.loops.asyncio",
    "uvicorn.loops.uvloop",
    "uvicorn.lifespan.on",
    "uvicorn.lifespan.off",
    "uvicorn.protocols.http.auto",
    "uvicorn.protocols.http.h11_impl",
    "uvicorn.protocols.http.httptools_impl",
    "uvicorn.protocols.websockets.auto",
    "uvicorn.protocols.websockets.websockets_impl",
    "uvicorn.protocols.websockets.wsproto_impl",
    # Third-party deps used only from action/trigger data files. Keep this in
    # sync with the imports in backend/actions and backend/triggers: a missing
    # entry does not fail the build, it just drops that action at runtime with
    # "failed to load action ...: No module named ...".
    "croniter",
    # Notifications. Only actions/send_notification.py imports this, and
    # that file ships as data, so nothing on the import graph reaches it.
    "desktop_notifier",
    "psutil",
    "pyperclip",
    "requests",
    "simpleeval",
    "tkinter",
    "tzlocal",
    "watchdog.observers",
    "zoneinfo",
]

if IS_LINUX:
    hiddenimports += [
        # Linux tray is StatusNotifierItem over D-Bus, imported lazily by tray.
        "tray_sni",
        "dbus_fast",
        "evdev",
        "pulsectl",
        "pynput.keyboard._xorg",
        "pynput.mouse._xorg",
        "pynput._util.xorg",
        "desktop_notifier.backends.dbus",
    ]
if IS_WINDOWS:
    hiddenimports += [
        "pystray",
        "comtypes",
        "pycaw",
        "pynput.keyboard._win32",
        "pynput.mouse._win32",
        "pynput._util.win32",
        "desktop_notifier.backends.winrt",
        "win32timezone",
        # Windows has no system tz database; tzlocal/zoneinfo need the wheel.
        "tzdata",
    ]

a = Analysis(
    [str(BACKEND / "main.py")],
    # backend/ modules import each other flat ("import config"), so it has to
    # be on the search path when the spec is run from the repo root.
    pathex=[str(BACKEND)],
    binaries=[],
    # desktop_notifier.common resolves resources/python.png at import time,
    # so that package data has to be on disk or importing it raises.
    # icon.png lands at the archive root, where paths.ICON_FILE looks for it.
    datas=plugin_datas("actions")
    + plugin_datas("triggers")
    + collect_data_files("desktop_notifier")
    + [(str(ROOT / "packaging" / "icon.png"), ".")],
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name="quartzd",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    # UPX is off: it is frequently absent on build machines and has a history
    # of corrupting shared libraries, for a saving that does not matter here.
    upx=False,
    upx_exclude=[],
    runtime_tmpdir=None,
    # No console window on Windows, where this autostarts at login. On Linux
    # the console is just the parent terminal or the journal.
    console=not IS_WINDOWS,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
