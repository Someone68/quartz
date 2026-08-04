import dialogs
from models import ActionDef, ActionInput, ActionOutput


def _run(inputs: dict, context: dict) -> dict:
    response = dialogs.prompt(
        title=str(inputs["title"]),
        prompt_text=str(inputs["prompt"]),
        icon=inputs.get("icon", "question"),
        backend=inputs.get("backend", "auto"),
    )
    return {"response": response}


ACTION = ActionDef(
    id="input.msgbox",
    category="Input",
    name="Dialog Box",
    description="Display a dialog box with a given title and prompt and accept input from the user.",
    icon="chat_add_on",
    color="green",
    platforms=["linux"],
    inputs=[
        ActionInput(name="title", type="string", label="Title", required=True, tooltip="The title of the dialog box. Will appear as the window title most of the time."),
        ActionInput(name="prompt", type="string", label="Prompt", required=True, tooltip="The prompt message to display in the dialog box."),
        ActionInput(
            name="icon",
            type="choice",
            label="Icon",
            required=False,
            options=["info", "warning", "error", "question"],
            default="question",
            tooltip="The icon to display in the dialog box.",
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
    outputs=[
        ActionOutput(name="response", type="string", label="Response"),
    ],
    run=_run,
)
