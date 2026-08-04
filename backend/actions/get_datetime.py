from models import ActionDef, ActionInput, ActionOutput
from tzlocal import get_localzone_name
from zoneinfo import available_timezones, ZoneInfo
from datetime import datetime


def _run(inputs: dict, context: dict) -> dict:
    timezone = inputs.get("timezone", "local")

    if timezone == "local":
        timezone = get_localzone_name()

    time = datetime.now(ZoneInfo(timezone)).isoformat()
    return {"datetime": time}

zones = sorted(z for z in available_timezones() if "/" in z and not z.startswith(("Etc/", "SystemV/")))

ACTION = ActionDef(
    id="system.get_time",
    category="System",
    name="Get Date & Time",
    description="Retrieves the current date and time.",
    icon="alarm",
    color="amber",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(
            name="timezone",
            label="Timezone",
            type="choice",
            options=["UTC", "local", *zones],
            default="local",
        ),
    ],
    outputs=[
        ActionOutput(
            name="datetime",
            label="Datetime in ISO format.",
            type="string",
        ),
    ],
    run=_run,
)
