import os
import subprocess
import tkinter as tk
from tkinter import simpledialog

from models import ActionDef, ActionInput, ActionOutput


def _run(inputs: dict, context: dict) -> dict:
    title = inputs["title"]
    prompt = inputs["prompt"]
    icon = inputs.get("icon", "info")
    backend = inputs.get("backend", "auto")

    de = str(os.environ.get("XDG_CURRENT_DESKTOP")).lower()
    if de == "kde" and backend == "auto" or backend == "kdialog (kde)":
        result = subprocess.run(
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
                "--inputbox",
                prompt,
            ],
            capture_output=True,
            text=True,
        )
        body = result.stdout.strip()
    elif de == "gnome" and backend == "auto" or backend == "zenity (gnome)":
        result = subprocess.run(
            [
                "zenity",
                "--info",
                "--text",
                prompt,
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
            ],
            capture_output=True,
            text=True,
        )
        body = result.stdout.strip()
    else:
        root = tk.Tk()
        root.withdraw()
        body = simpledialog.askstring(title, prompt)
        root.destroy()

    return {"response": body}


ACTION = ActionDef(
    id="input.msgbox",
    category="Input",
    name="Dialog Box",
    description="Display a dialog box with a given title and prompt and accept input from the user.",
    icon="chat_add_on",
    color="green",
    platforms=["linux"],
    inputs=[
        ActionInput(name="title", type="string", label="Title", required=True),
        ActionInput(name="prompt", type="string", label="Prompt", required=True),
        ActionInput(
            name="icon",
            type="choice",
            label="Icon",
            required=False,
            options=["info", "warning", "error", "question"],
            default="question",
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
    outputs=[
        ActionOutput(name="response", type="string", label="Response"),
    ],
    run=_run,
)
