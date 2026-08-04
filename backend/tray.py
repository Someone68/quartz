"""System-tray icon for the daemon.

Runs inside the daemon process so there is one always-on thing the user can see
and control. It is strictly optional: the tray only starts when a GUI session is
present (so a headless, linger-started daemon keeps firing triggers with no
tray), and any failure to build it is swallowed — triggers must never depend on
a tray being available.
"""

import os
import signal
import subprocess
import sys
import threading

import trigger_manager


def has_gui_session() -> bool:
    """True when a desktop session exists to host a tray icon."""
    if sys.platform == "win32":
        return True
    if sys.platform == "darwin":
        return True
    # Linux/BSD: needs an X or Wayland display.
    return bool(os.environ.get("DISPLAY") or os.environ.get("WAYLAND_DISPLAY"))


def _icon_image():
    """Build the tray image in memory (no bundled asset to ship or freeze)."""
    from PIL import Image, ImageDraw

    size = 64
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([4, 4, size - 4, size - 4], radius=14, fill=(124, 77, 255, 255))
    d.text((size // 2, size // 2), "Q", fill="white", anchor="mm")
    return img


def _open_ui() -> None:
    """Launch the UI binary, detached, so it outlives the tray callback."""
    exe = _ui_path()
    if not exe:
        print("Tray: no quartz UI binary found to open.")
        return
    try:
        subprocess.Popen(
            [exe],
            start_new_session=(sys.platform != "win32"),
            close_fds=True,
        )
    except Exception as e:
        print(f"Tray: failed to open UI ({e}).")


def _ui_path() -> str | None:
    if sys.platform == "win32":
        # MSIX ships quartz.exe next to quartzd.exe.
        exe = os.path.join(os.path.dirname(sys.executable), "quartz.exe")
        return exe if os.path.exists(exe) else None
    home = os.environ.get("HOME", "")
    for p in ("/usr/bin/quartz", os.path.join(home, ".local/bin/quartz")):
        if os.path.exists(p):
            return p
    return None


def _quit() -> None:
    """Ask the daemon to shut down gracefully so the handshake is cleaned up."""
    # SIGINT drives uvicorn's graceful shutdown, which runs the lifespan
    # teardown (stops listeners, removes runtime.json).
    os.kill(os.getpid(), signal.SIGINT)


def _build_icon(port: int):
    import pystray

    paused = {"on": False}

    def toggle_pause(icon, item):
        if paused["on"]:
            trigger_manager.start_all()
            paused["on"] = False
        else:
            trigger_manager.stop_all()
            paused["on"] = True

    menu = pystray.Menu(
        pystray.MenuItem(f"Quartz — port {port}", None, enabled=False),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem("Open Quartz", lambda icon, item: _open_ui(), default=True),
        pystray.MenuItem(
            "Pause triggers",
            toggle_pause,
            checked=lambda item: paused["on"],
        ),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem("Quit", lambda icon, item: _quit()),
    )
    return pystray.Icon("quartz", _icon_image(), "Quartz", menu)


def start(port: int) -> None:
    """Start the tray on a background thread if a GUI session is present."""
    if not has_gui_session():
        print("Tray: no GUI session, running headless.")
        return

    def run():
        try:
            _build_icon(port).run()
        except Exception as e:
            # A missing tray backend (e.g. no AppIndicator) must not take the
            # daemon down; triggers keep running regardless.
            print(f"Tray: disabled ({e}).")

    threading.Thread(target=run, name="tray", daemon=True).start()
