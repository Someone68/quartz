import time

from models import TriggerDef, TriggerInput, TriggerOutput
from watchdog.events import FileSystemEventHandler
from watchdog.observers import Observer

# Editors save atomically (write temp + rename + metadata flush), emitting
# multiple modified events per logical edit. Coalesce same-path events within
# this window into a single fire.
_DEBOUNCE_SECONDS = 0.5


class _Handler(FileSystemEventHandler):
    def __init__(self, fire):
        self.fire = fire
        self._last = {}

    def on_modified(self, event):
        # Content changes only. Skip dirs and structural events.
        if event.is_directory:
            return
        now = time.monotonic()
        last = self._last.get(event.src_path)
        if last is not None and now - last < _DEBOUNCE_SECONDS:
            self._last[event.src_path] = now
            return
        self._last[event.src_path] = now
        self.fire(
            {
                "event_type": event.event_type,
                "path": event.src_path,
            }
        )


class FileContentWatchListener:
    def __init__(self, config, fire):
        self.config, self.fire = config, fire
        self._obs = Observer()

    def start(self):
        self._obs.schedule(
            _Handler(self.fire),
            self.config["path"],
            recursive=self.config.get("recursive", True),
        )
        self._obs.start()

    def stop(self):
        self._obs.stop()
        self._obs.join()


TRIGGER = TriggerDef(
    type="directory_contents_watch",
    name="Directory Content Watch",
    icon="file-text",
    description="Triggers on file content changes within a directory",
    color="green",
    platforms=["linux", "windows"],
    inputs=[
        TriggerInput(name="path", type="path", label="Directory", required=True),
        TriggerInput(name="recursive", type="boolean", label="Recursive", default=True),
    ],
    outputs=[
        TriggerOutput(name="event_type", type="string", label="Event type"),
        TriggerOutput(name="path", type="path", label="Path"),
    ],
    make_listener=lambda config, fire: FileContentWatchListener(config, fire),
)
