import pyperclip
from models import TriggerDef, TriggerInput, TriggerOutput
from triggers._base import PollingListener


class ClipboardListener(PollingListener):
    def setup(self):
        self.interval = float(self.config.get("poll_interval", 1.0))
        self._last = pyperclip.paste()

    @staticmethod
    def sample():
        # Shared read: clipboard is global, so one paste() serves all
        # clipboard listeners on the same interval.
        return pyperclip.paste()

    def detect(self, cur):
        if cur != self._last:
            self._last = cur
            self.fire({"content": cur})


TRIGGER = TriggerDef(
    type="clipboard",
    name="Clipboard Change",
    icon="clipboard",
    description="Triggers on clipboard content changes",
    color="green",
    platforms=["linux", "windows"],
    inputs=[
        TriggerInput(
            name="poll_interval", type="number", label="Poll interval (s)", default=1.0
        )
    ],
    outputs=[TriggerOutput(name="content", type="string", label="Clipboard content")],
    make_listener=lambda config, fire: ClipboardListener(config, fire),
)
