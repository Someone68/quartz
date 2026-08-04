import dialogs
from models import ActionDef, ActionInput, ActionOutput


def _run(inputs: dict, context: dict) -> dict:
    dialogs.message(
        title=str(inputs["title"]),
        body=str(inputs["body"]),
        icon=inputs.get("icon", "info"),
        backend=inputs.get("backend", "auto"),
        width=inputs.get("width"),
        height=inputs.get("height"),
    )
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
        ActionInput(name="title", type="string", label="Title", required=True, tooltip="The title of the dialog box. Will appear as the window title most of the time."),
        ActionInput(name="body", type="string", label="Body", required=True, tooltip="The body of the message box. This is the main message that will be displayed."),
        ActionInput(
            name="icon",
            type="choice",
            label="Icon",
            required=False,
            options=["info", "warning", "error", "question"],
            default="info",
            tooltip="The icon to display in the dialog box."
        ),
        ActionInput(
            name="backend",
            type="choice",
            label="Backend",
            required=False,
            options=["auto", "kdialog (kde)", "zenity (gnome)", "tk (fallback)"],
            default="auto",
            tooltip="The backend to use for the dialog box. Defaults to auto, which will use the best available backend based on the environment. If you are on KDE or use QT applications, you may want to set this to kdialog. If you are on GNOME or niri, or use GTK applications, you may want to set this to zenity. Otherwise, tk will most likely work but be ugly. Each backend requires its respective tool installed.",
        ),
        ActionInput(
            name="width", type="number", label="Width (zenity)", required=False, tooltip="The width of the dialog box in logical pixels. Only works if you are using zenity."
        ),
        ActionInput(
            name="height", type="number", label="Height (zenity)", required=False, tooltip="The height of the dialog box in logical pixels. Only works if you are using zenity."
        ),
    ],
    outputs=[],
    run=_run,
)
