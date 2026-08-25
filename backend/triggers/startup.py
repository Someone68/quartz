from models import TriggerDef
from triggers._base import booting


class StartupListener:
    def __init__(self, config, fire):
        self.config = config
        self.fire = fire

    def start(self):
        # start() runs again on every save of the shortcut, because editing
        # one re-registers its listener. Only the boot sweep is a real start.
        if booting():
            self.fire({})

    def stop(self):
        pass


TRIGGER = TriggerDef(
    type="startup", name="On Startup", icon="power",
    description="Triggers once when Quartz starts",
    color="purple", platforms=["linux", "windows"],
    inputs=[],
    outputs=[],
    make_listener=lambda config, fire: StartupListener(config, fire),
)
