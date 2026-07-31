from models import ActionDef, ActionInput, ActionOutput
from pathlib import Path

def _run(inputs: dict, context: dict):
    path = inputs["path"]
    content = inputs["content"]
    error = inputs["error"]
    overwrite = inputs["overwrite"]

    path_expanded = Path(path).expanduser()
    exists = path_expanded.exists()
    path_expanded.touch(exist_ok=not error)
    if (content and not exists) or overwrite:
        path_expanded.write_text(content if content else "")
    return {"path": str(path_expanded)}

ACTION = ActionDef(
    id="filesystem.create_file",
    category="Filesystem",
    name="Create file",
    description="Creates a file with the given content.",
    icon="post_add",
    color="red",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(name="path", type="path", label="Path", required=True, tooltip="The path of the file to create. Use ~ to refer to the home directory."),
        ActionInput(name="content", type="string", label="Content", required=False, tooltip="The content to write to the file."),
        ActionInput(name="overwrite", type="boolean", label="Overwrite", required=False, default=False, tooltip="If true, the file will be overwritten if it already exists. If contents are not provided, will make an empty file."),
        ActionInput(name="error", type="boolean", label="Error if exists", required=True, default=False, tooltip="If true, an error will be raised if the file already exists."),
    ],
    outputs=[
        ActionOutput(name="path", type="path", label="Path"),
    ],
    run=_run,
)
