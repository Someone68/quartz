import psutil
from models import TriggerDef, TriggerInput, TriggerOutput
from triggers._base import PollingListener


class AppListener(PollingListener):
    def setup(self) -> None:
        self.target = self.config["app"].lower()
        self.was_running = self.target in self.sample()

    @staticmethod
    def sample() -> set[str]:
        # One process scan shared by every app-open listener, instead of
        # one full process_iter per listener per interval.
        return {
            p.info["name"].lower()
            for p in psutil.process_iter(["name"])
            if p.info["name"]
        }

    def detect(self, names: set[str]) -> None:
        now = self.target in names
        if not now and self.was_running:
            self.fire({})
        self.was_running = now


TRIGGER = TriggerDef(
    type="app_close",
    name="App Close",
    icon="close",
    description="Triggers when an application is closed",
    color="blue",
    platforms=["linux", "windows"],
    inputs=[TriggerInput(type="app", name="app", label="App", required=True, tooltip="The application to trigger on. Will work for most applications.")],
    outputs=[],
    make_listener=lambda config, fire: AppListener(config, fire),
)
