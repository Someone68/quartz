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
        if now and not self.was_running:
            self.fire({})
        self.was_running = now


TRIGGER = TriggerDef(
    type="app_open",
    name="App Open",
    icon="open_in_new",
    description="Triggers when an application is opened",
    color="blue",
    platforms=["linux", "windows"],
    inputs=[TriggerInput(type="string", name="app", label="App Name", required=True)],
    outputs=[],
    make_listener=lambda config, fire: AppListener(config, fire),
)
