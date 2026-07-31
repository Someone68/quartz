from models import ActionDef, ActionInput, ActionOutput
from pathlib import Path

def _run(inputs: dict, context: dict):
    path = inputs["path"]
    new_name = inputs["new_name"]
    error = inputs["error"]

    path_expanded = Path(path).expanduser()
    if error and not path_expanded.exists():
        raise FileNotFoundError(f"Path does not exist: {path}")
    path_expanded.rename(path_expanded.parent / new_name)

    return {}

ACTION = ActionDef(
    id="filesystem.rename_or_move",
    category="Filesystem",
    name="Rename or move file or directory",
    description="Renames or moves a file or directory.",
    icon="save_as",
    color="red",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(name="path", type="path", label="Path", required=True, tooltip="The path of the file or directory to move or rename. Use ~ to refer to the home directory."),
        ActionInput(name="new_name", type="string", label="New Path", required=True, tooltip="The new path of the file or directory. Can also be a relative path (e.g. './new_dir/abc.txt' or '../abc.txt')"),
        ActionInput(name="error", type="boolean", label="Error if missing", required=True, default=False, tooltip="If true, an error will be raised if the file or directory does not exist."),
    ],
    outputs=[],
    run=_run,
)
