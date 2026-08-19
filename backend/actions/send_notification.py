from models import ActionDef, ActionInput
from plyer import notification
import platform, subprocess

from subproc import clean_env


def _run(inputs: dict, context: dict) -> dict:
    title = str(inputs.get("title") or "")
    message = str(inputs.get("message") or "")
    try:
        timeout = float(inputs.get("timeout") or 5)
    except (TypeError, ValueError):
        timeout = 5.0

    if platform.system() == "Linux":
        subprocess.run(
            ["notify-send", "-t", str(int(timeout * 1000)), title, message],
            check=False,
            env=clean_env(),
        )
    else:
        assert notification is not None
        notification.notify(title=title, message=message, timeout=int(timeout)) # type: ignore[reportOptionalCall]
    return {}


ACTION = ActionDef(
    id="system.send_notification",
    category="System",
    name="Send Notification",
    description="Shows a notification.",
    icon="notifications",
    color="amber",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(name="title", type="string", label="Title", required=False, tooltip="The title of the notification."),
        ActionInput(name="message", type="string", label="Message", required=False, tooltip="The message of the notification."),
        ActionInput(name="timeout", type="number", label="Timeout (seconds)", required=False, default=5, tooltip="The duration the notification will be displayed."),
    ],
    outputs=[],
    run=_run,
)
