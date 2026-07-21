from models import TriggerDef


class StartupListener:
    def __init__(self, config, fire):
        self.config = config
        self.fire = fire

    def start(self):
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
