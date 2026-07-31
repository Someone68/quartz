from models import ActionDef, ActionInput
from plyer import notification
import platform, subprocess


def _run(inputs: dict, context: dict) -> dict:
    title = inputs.get("title", "")
    message = inputs.get("message", "")
    timeout = inputs.get("timeout", 5)

    if platform.system() == "Linux":
        subprocess.run(
            ["notify-send", "-t", str(timeout * 1000), title, message],
            check=False,
        )
    else:
        assert notification is not None
        notification.notify(title=title, message=message, timeout=timeout) # type: ignore[reportOptionalCall]
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
        ActionInput(name="title", type="string", label="Title", required=False),
        ActionInput(name="message", type="string", label="Message", required=False),
        ActionInput(name="timeout", type="number", label="Timeout (seconds)", required=False,default=5),
    ],
    outputs=[],
    run=_run,
)
