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
