from models import ActionDef, ActionInput, ActionOutput
from pathlib import Path

def _run(inputs: dict, context: dict):
    path = inputs["path"]

    path_expanded = Path(path).expanduser()
    path_expanded.unlink(missing_ok=not inputs["error"])

    return {}

ACTION = ActionDef(
    id="filesystem.delete_file",
    category="Filesystem",
    name="Delete file",
    description="Deletes a file.",
    icon="contract_delete",
    color="red",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(name="path", type="path", label="Path", required=True, tooltip="The path of the file to delete. Use ~ to refer to the home directory."),
        ActionInput(name="error", type="boolean", label="Error if missing", required=True, default=False, tooltip="If true, an error will be raised if the file does not exist."),
    ],
    outputs=[],
    run=_run,
)
