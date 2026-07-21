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
