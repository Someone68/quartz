import threading
import time
from datetime import datetime

from croniter import croniter
from models import TriggerDef, TriggerInput, TriggerOutput

_TICK_SECONDS = 1.0


def _hour_minute(value):
    # datetime input arrives as ISO string (or datetime). Only time-of-day
    # matters; the date part is ignored — this is a recurring schedule.
    if isinstance(value, datetime):
        dt = value
    elif value:
        dt = datetime.fromisoformat(value)
    else:
        dt = datetime(1970, 1, 1)  # midnight fallback
    return dt.hour, dt.minute


def _build_cron(config):
    freq = config.get("frequency", "daily")
    hh, mm = _hour_minute(config.get("time"))
    if freq == "minutes":
        n = int(config.get("interval", 1))
        return f"*/{n} * * * *"
    if freq == "hourly":
        return f"{mm} * * * *"
    if freq == "daily":
        return f"{mm} {hh} * * *"
    if freq == "weekly":
        return f"{mm} {hh} * * {int(config.get('day_of_week', 1))}"
    if freq == "monthly":
        return f"{mm} {hh} {int(config.get('day_of_month', 1))} * *"
    raise ValueError(f"unknown frequency: {freq}")


class ScheduleListener:
    def __init__(self, config, fire):
        self.config, self.fire = config, fire
        self._stop = threading.Event()
        self._thread = None

    def start(self):
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()

    def stop(self):
        self._stop.set()
        if self._thread:
            self._thread.join(timeout=2)

    def _loop(self):
        cron = _build_cron(self.config)
        # Time-of-day comes from the picker as local wall-clock time, so the
        # cron must be evaluated against the local clock. Using UTC here fired
        # at the wrong hour (off by the tz offset).
        base = datetime.now()
        it = croniter(cron, base)
        nxt = it.get_next(datetime)
        while not self._stop.is_set():
            now = datetime.now()
            if now >= nxt:
                self.fire(
                    {
                        "fired_at": now.isoformat(),
                        "scheduled_for": nxt.isoformat(),
                    }
                )
                while nxt <= now:
                    nxt = it.get_next(datetime)
            self._stop.wait(_TICK_SECONDS)


TRIGGER = TriggerDef(
    type="schedule",
    name="Schedule",
    icon="clock",
    description="Triggers on a recurring schedule",
    color="green",
    platforms=["linux", "windows"],
    inputs=[
        TriggerInput(
            name="frequency",
            type="choice",
            label="Frequency",
            required=True,
            options=["minutes", "hourly", "daily", "weekly", "monthly"],
            default="daily",
        ),
        TriggerInput(
            name="time",
            type="datetime",
            label="Time of day",
            help="Used for daily, weekly, and monthly. Date part ignored.",
        ),
        TriggerInput(
            name="interval",
            type="number",
            label="Every N minutes",
            default=1,
            help="Used when frequency is minutes.",
        ),
        TriggerInput(
            name="day_of_week",
            type="number",
            label="Day of week (0=Sun)",
            default=1,
            help="Used when frequency is weekly.",
        ),
        TriggerInput(
            name="day_of_month",
            type="number",
            label="Day of month (1-31)",
            default=1,
            help="Used when frequency is monthly.",
        ),
    ],
    outputs=[
        TriggerOutput(name="fired_at", type="string", label="Fired at"),
        TriggerOutput(name="scheduled_for", type="string", label="Scheduled for"),
    ],
    make_listener=lambda config, fire: ScheduleListener(config, fire),
)
