from models import ActionDef, ActionInput, ActionOutput
from pathlib import Path

def _run(inputs: dict, context: dict):
    path = inputs["path"]
    error = inputs["error"]

    path_expanded = Path(path).expanduser()
    path_expanded.mkdir(parents=True, exist_ok=not error)

    return {"path": str(path_expanded)}

ACTION = ActionDef(
    id="filesystem.create_directory",
    category="Filesystem",
    name="Create directory",
    description="Creates a directory.",
    icon="create_new_folder",
    color="red",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(name="path", type="path", label="Path", required=True, tooltip="The path of the directory to create. Use ~ to refer to the home directory."),
        ActionInput(name="error", type="boolean", label="Error if exists", required=True, default=False, tooltip="If true, an error will be raised if the directory already exists."),
    ],
    outputs=[
        ActionOutput(name="path", type="path", label="Path"),
    ],
    run=_run,
)
