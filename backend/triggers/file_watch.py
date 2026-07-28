import time

from models import TriggerDef, TriggerInput, TriggerOutput
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Editors (nano, vim, etc.) save atomically: write temp + rename + metadata
# flush, which emits multiple modified events for one logical edit. Coalesce
# events on the same path within this window into a single fire.
_DEBOUNCE_SECONDS = 0.5


class _Handler(FileSystemEventHandler):
    def __init__(self, fire):
        self.fire = fire
        self._last = {}

    def on_modified(self, event):
        # Content changes only. Skip directory events and non-content
        # event types (created/deleted/moved/attribute) so a single edit
        # doesn't multi-fire the trigger.
        if event.is_directory:
            return
        now = time.monotonic()
        last = self._last.get(event.src_path)
        if last is not None and now - last < _DEBOUNCE_SECONDS:
            self._last[event.src_path] = now
            return
        self._last[event.src_path] = now
        self.fire({
            'event_type': event.event_type,
            'path': event.src_path,
        })


class FileWatchListener:
    def __init__(self, config, fire):
        self.config, self.fire = config, fire
        self._obs = Observer()

    def start(self):
        self._obs.schedule(
            _Handler(self.fire),
            self.config['path'],
            recursive=self.config.get('recursive', False),
        )
        self._obs.start()

    def stop(self):
        self._obs.stop()
        self._obs.join()


TRIGGER = TriggerDef(
    type="file_watch", name="File Watch", icon="folder",
    description="Triggers on file content changes in a path",
    color="blue", platforms=["linux", "windows"],
    inputs=[
        TriggerInput(name="path", type="path", label="Path", required=True),
        TriggerInput(name="recursive", type="boolean", label="Recursive", default=False),
    ],
    outputs=[TriggerOutput(name="event_type", type="string", label="Event type"), TriggerOutput(name="path", type="path", label="Path")],
    make_listener=lambda config, fire: FileWatchListener(config, fire),
)
