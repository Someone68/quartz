"""Shared dialog backend for the msgbox / dialog-box actions.

The backend runs headless in the background, so dialogs are shown by spawning a
short-lived native helper (zenity or kdialog) when available, falling back to a
bundled Tk dialog. All GUI imports are lazy so that a missing library (e.g. no
libtk on the host) never prevents the action from *registering* — it only fails
if that specific backend is actually used with nothing else available.
"""

import os
import shutil
import subprocess

Icon = str  # one of: info, warning, error, question


def _has(tool: str) -> bool:
    return shutil.which(tool) is not None


def pick_backend(preferred: str = "auto") -> str:
    """Resolve the backend to use. `preferred` is the action's `backend` input."""
    if preferred.startswith("kdialog"):
        return "kdialog"
    if preferred.startswith("zenity"):
        return "zenity"
    if preferred.startswith("tk"):
        return "tk"

    # auto: honour the desktop environment first, then fall back to whatever is
    # actually installed, then to bundled Tk as the universal floor.
    de = str(os.environ.get("XDG_CURRENT_DESKTOP", "")).lower()
    if "kde" in de and _has("kdialog"):
        return "kdialog"
    if _has("zenity"):
        return "zenity"
    if _has("kdialog"):
        return "kdialog"
    return "tk"


_KDIALOG_ICON = {
    "info": "dialog-information",
    "error": "dialog-error",
    "warning": "dialog-warning",
    "question": "dialog-question",
}
_ZENITY_TYPE = {
    "info": "--info",
    "warning": "--warning",
    "error": "--error",
    "question": "--question",
}


def message(
    title: str,
    body: str,
    icon: Icon = "info",
    backend: str = "auto",
    width: int | None = None,
    height: int | None = None,
) -> None:
    """Show a message box (no return value)."""
    be = pick_backend(backend)

    if be == "kdialog":
        flag = {"error": "--error", "warning": "--sorry"}.get(icon, "--msgbox")
        subprocess.run(
            ["kdialog", "--title", title, "--icon",
             _KDIALOG_ICON.get(icon, "dialog-information"), flag, body]
        )
    elif be == "zenity":
        subprocess.run(
            ["zenity", _ZENITY_TYPE.get(icon, "--info"),
             "--title", title, "--text", body,
             *(["--width", str(width)] if width else []),
             *(["--height", str(height)] if height else [])]
        )
    else:
        _tk_message(title, body, icon)


def prompt(
    title: str,
    prompt_text: str,
    icon: Icon = "question",
    backend: str = "auto",
) -> str | None:
    """Ask the user for text. Returns the string, or None if cancelled."""
    be = pick_backend(backend)

    if be == "kdialog":
        r = subprocess.run(
            ["kdialog", "--title", title, "--icon",
             _KDIALOG_ICON.get(icon, "dialog-question"), "--inputbox", prompt_text],
            capture_output=True, text=True,
        )
        return r.stdout.strip() if r.returncode == 0 else None
    elif be == "zenity":
        r = subprocess.run(
            ["zenity", "--entry", "--title", title, "--text", prompt_text],
            capture_output=True, text=True,
        )
        return r.stdout.strip() if r.returncode == 0 else None
    else:
        return _tk_prompt(title, prompt_text)


def _tk_message(title: str, body: str, icon: Icon) -> None:
    import tkinter as tk
    from tkinter import messagebox

    root = tk.Tk()
    root.withdraw()
    fn = {
        "warning": messagebox.showwarning,
        "error": messagebox.showerror,
        "question": messagebox.showinfo,
    }.get(icon, messagebox.showinfo)
    fn(title, body)
    root.destroy()


def _tk_prompt(title: str, prompt_text: str) -> str | None:
    import tkinter as tk
    from tkinter import simpledialog

    root = tk.Tk()
    root.withdraw()
    body = simpledialog.askstring(title, prompt_text)
    root.destroy()
    return body
