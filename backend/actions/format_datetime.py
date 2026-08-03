from models import ActionDef, ActionInput, ActionOutput
from tzlocal import get_localzone_name
from zoneinfo import available_timezones, ZoneInfo
from datetime import datetime


def _run(inputs: dict, context: dict) -> dict:
    unformatted = str(inputs.get("iso_datetime"))
    format_template = inputs.get("format_template", "%Y-%m-%d %H:%M:%S")
    dt = datetime.fromisoformat(unformatted)
    return {"formatted_datetime": dt.strftime(format_template)}

cur_time = datetime.now()

ACTION = ActionDef(
    id="misc.format_datetime",
    category="Misc",
    name="Format ISO Datetime",
    description="Formats an ISO datetime string to be more readable.",
    icon="chronic",
    color="orange",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(
            name="iso_datetime",
            label="ISO Datetime",
            tooltip="The ISO datetime string to format. Defaults to the current time.",
            type="string",
            default=cur_time.isoformat(),
        ),
        ActionInput(
            name="format_template",
            label="Format template",
            tooltip="Format template. Use Python strftime format. Guide:\n %Y - Year (4 digits)\n %y - Year (2 digits)\n %m - Month (01-12)\n %B - Month name (Full)\n %b - Month name (Short)\n %d - Day (01-31)\n %j - Day of year (001-366)\n %A - Day of week (Full)\n %a - Day of week (Short)\n %w - Day of week (0-6)\n %H - Hour (00-23)\n %I - Hour (01-12)\n %M - Minute (00-59)\n %S - Second (00-59)\n %p - AM/PM\n %f - Microsecond (000000-999999)\n %U - Week number (Sunday start)\n %W - Week number (Monday start)\n %c - Local date and time\n %x - Local date\n %X - Local time\n %z - UTC offset\n %Z - Timezone name",
            type="string",
            default="%Y-%m-%d %H:%M:%S",
        ),
    ],
    outputs=[
        ActionOutput(
            name="formatted_datetime",
            label="Formatted date & time.",
            type="string",
        ),
    ],
    run=_run,
)
