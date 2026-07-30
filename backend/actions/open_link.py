import subprocess
import shutil

from models import ActionDef, ActionInput


def _run(inputs: dict, context: dict) -> dict:
    if not shutil.which("xdg-open"):
        raise RuntimeError("xdg-open not found")

    url = inputs["url"]
    subprocess.run(["xdg-open", url])
    return {}


ACTION = ActionDef(
    id="system.open_link",
    category="System",
    name="Open Link",
    description="Open a link in the default app.",
    icon="link",
    color="amber",
    platforms=["linux"],
    inputs=[
        ActionInput(name="url", type="string", label="URL", required=True, tooltip="Open a link in the default app. For example, `https://example.com`. Can also be used to open file links and other applications (e.g. `file:///home/user/Documents` or `spotify://`)"),
    ],
    outputs=[],
    run=_run,
)
