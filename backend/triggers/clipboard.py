from backend.models import TriggerDef, TriggerInput
from backend.triggers._base import PollingListener
import pyperclip


class ClipboardListener(PollingListener):
    def setup(self):
        self.interval = float(self.config.get("poll_interval", 1.0))
        self._last = pyperclip.paste()
    def poll(self):
        cur = pyperclip.paste()
        if cur != self._last:
            self._last = cur
            self.fire({"content": cur})

TRIGGER = TriggerDef(
    type="clipboard", name="Clipboard Change", icon="clipboard", description="Triggers on clipboard content changes", color="green",
    platforms=["linux", "windows"],
    inputs=[TriggerInput(name="poll_interval", type="number", label="Poll interval (s)", default=1.0)],
    make_listener=lambda config, fire: ClipboardListener(config, fire),
)
