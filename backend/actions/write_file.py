from models import ActionDef, ActionInput, ActionOutput
from pathlib import Path

def _run(inputs: dict, context: dict):
    path = inputs["path"]
    path_expanded = Path(path).expanduser()
    content = inputs["content"]
    mode = inputs["mode"]

    if mode == "write":
        path_expanded.write_text(content)
    elif mode == "append":
        with path_expanded.open("a") as f:
            f.write(content)

ACTION = ActionDef(
    id="filesystem.write_file",
    category="Filesystem",
    name="Write file",
    description="Writes the contents of a file.",
    icon="edit",
    color="red",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(name="path", type="path", label="Path", required=True, tooltip="The path of the file to write. Use ~ to refer to the home directory."),
        ActionInput(name="mode", type="choice", label="Mode", required=True, tooltip="The mode to use when writing the file.", options=["write", "append"]),
        ActionInput(name="content", type="string", label="Content", required=True, tooltip="The content to write to the file."),
    ],
    outputs=[
    ],
    run=_run,
)
