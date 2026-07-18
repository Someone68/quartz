from backend.models import TriggerDef, TriggerInput
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler


class _Handler(FileSystemEventHandler):
    def __init__(self, fire, events):
        self.fire = fire
        self.events = events
    def on_any_event(self, event):
        if self.events and event.event_type not in self.events:
            return
        self.fire({
            'event_type': event.event_type,
            'path': event.src_path,
        })

class FileWatchListener:
    def __init__(self, config, fire):
        self.config, self.fire = config, fire
        self._obs = Observer()
    def start(self):
        self._obs.schedule( _Handler(self.fire, self.config.events), self.config.path, self.config.get('recursive', False))
        self._obs.start()
    def stop(self):
        self._obs.stop()
        self._obs.join()
