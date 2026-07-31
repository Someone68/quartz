import subprocess
import shutil
import sys

from models import ActionDef, ActionInput


def _run(inputs: dict, context: dict) -> dict:
    url = inputs["url"]

    if sys.platform.startswith("win"):
        import os
        os.startfile(url)

    if not shutil.which("xdg-open"):
        raise RuntimeError("xdg-open not found")

    subprocess.run(["xdg-open", url])
    return {}


ACTION = ActionDef(
    id="system.open_link",
    category="System",
    name="Open Link",
    description="Open a link in the default app.",
    icon="link",
    color="amber",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(name="url", type="string", label="URL", required=True, tooltip="Open a link in the default app. For example, `https://example.com`. Can also be used to open file links and other applications (e.g. `file:///home/user/Documents` or `spotify://`)"),
    ],
    outputs=[],
    run=_run,
)
