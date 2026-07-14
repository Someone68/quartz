import os
import subprocess
import tkinter as tk
from tkinter import messagebox

from models import ActionDef, ActionInput, ActionOutput


def _run(inputs: dict, context: dict) -> dict:
    title = inputs["title"]
    body = inputs["body"]
    icon = inputs.get("icon", "info")
    backend = inputs.get("backend", "auto")

    de = str(os.environ.get("XDG_CURRENT_DESKTOP")).lower()
    if de == "kde" and backend == "auto" or backend == "kdialog (kde)":
        subprocess.run(
            [
                "kdialog",
                "--title",
                title,
                "--icon",
                "dialog-information"
                if icon == "info"
                else "dialog-error"
                if icon == "error"
                else "dialog-warning"
                if icon == "warning"
                else "dialog-question",
                "--msgbox"
                if icon == "info"
                else "--error"
                if icon == "error"
                else "--sorry"
                if icon == "warning"
                else "--msgbox",
                body,
            ]
        )
    elif de == "gnome" and backend == "auto" or backend == "zenity (gnome)":
        subprocess.run(
            [
                "zenity",
                "--info",
                "--text",
                body,
                "--title",
                title,
                "--icon",
                icon,
                *(
                    ["--width", str(inputs.get("width", 400))]
                    if inputs.get("width")
                    else []
                ),
                *(
                    ["--height", str(inputs.get("height", 300))]
                    if inputs.get("height")
                    else []
                ),
            ]
        )
    else:
        root = tk.Tk()
        root.withdraw()
        messagebox.showinfo(title, body, icon=icon)
        root.destroy()

    return {}


ACTION = ActionDef(
    id="output.msgbox",
    category="Output",
    name="Message Box",
    description="Display a message box with a given title and body.",
    icon="info",
    color="pink",
    platforms=["linux"],
    inputs=[
        ActionInput(name="title", type="string", label="Title", required=True),
        ActionInput(name="body", type="string", label="Body", required=True),
        ActionInput(
            name="icon",
            type="choice",
            label="Icon",
            required=False,
            options=["info", "warning", "error", "question"],
            default="info",
        ),
        ActionInput(
            name="backend",
            type="choice",
            label="Backend",
            required=False,
            options=["auto", "kdialog (kde)", "zenity (gnome)", "tk (fallback)"],
            default="auto",
        ),
        ActionInput(
            name="width", type="number", label="Width (zenity)", required=False
        ),
        ActionInput(
            name="height", type="number", label="Height (zenity)", required=False
        ),
    ],
    outputs=[],
    run=_run,
)
