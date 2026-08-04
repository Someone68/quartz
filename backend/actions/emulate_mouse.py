import subprocess

from models import ActionDef, ActionInput, ActionOutput


def _run(inputs: dict, context: dict) -> dict:
    return {}


ACTION = ActionDef(
    id="system.emulate_mouse",
    category="System",
    name="Simulate Mouse Button",
    description="Simulates a mouse button press at the specified coordinates. Not implemented yet.",
    icon="mouse",
    color="amber",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(name="button", type="choice", label="Button", required=True, options=["left", "middle", "right"]),
        ActionInput(name="x", type="number", label="X", required=True),
        ActionInput(name="y", type="number", label="Y", required=True),
    ],
    outputs=[],
    run=_run,
)
