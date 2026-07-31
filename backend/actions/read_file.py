from models import ActionDef, ActionInput, ActionOutput
from pathlib import Path

def _run(inputs: dict, context: dict):
    path = inputs["path"]
    path_expanded = Path(path).expanduser()
    content = path_expanded.read_text()
    return {"content": content}

ACTION = ActionDef(
    id="filesystem.read_file",
    category="Filesystem",
    name="Read file",
    description="Reads the contents of a file.",
    icon="attachment",
    color="red",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(name="path", type="path", label="Path", required=True, tooltip="The path of the file to read. Use ~ to refer to the home directory."),
    ],
    outputs=[
        ActionOutput(name="content", type="string", label="Content"),
    ],
    run=_run,
)
