from models import ActionDef, ActionInput, ActionOutput
from pathlib import Path

import shutil

def _run(inputs: dict, context: dict):
    path = inputs["path"]
    recursive = inputs["recursive"]
    error = inputs["error"]

    path_expanded = Path(path).expanduser()
    if not path_expanded.exists():
        if error:
            raise FileNotFoundError(f"Directory does not exist: {path_expanded}")
        return {}
    if recursive:
        shutil.rmtree(path_expanded)
    else:
        path_expanded.rmdir()

    return {}

ACTION = ActionDef(
    id="filesystem.delete_directory",
    category="Filesystem",
    name="Delete directory",
    description="Deletes a directory.",
    icon="folder_delete",
    color="red",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(name="path", type="path", label="Path", required=True, tooltip="The path of the directory to delete. Use ~ to refer to the home directory."),
        ActionInput(name="recursive", type="boolean", label="Recursive", required=True, default=False, tooltip="If true, the directory will be deleted recursively. Must be true to delete non-empty directories."),
        ActionInput(name="error", type="boolean", label="Error if missing", required=True, default=False, tooltip="If true, an error will be raised if the directory does not exist."),
    ],
    outputs=[],
    run=_run,
)
