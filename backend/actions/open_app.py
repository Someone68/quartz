from get_apps import launch_by_name
from models import ActionDef, ActionInput


def _run(inputs: dict, context: dict) -> dict:
    launch_by_name(inputs["app"])
    return {}


ACTION = ActionDef(
    id="system.open_app",
    category="System",
    name="Open App",
    description="Open an application.",
    icon="apps",
    color="amber",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(name="app", type="app", label="App", required=True, tooltip="The application to open."),
    ],
    outputs=[],
    run=_run,
)
