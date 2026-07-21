from __future__ import annotations
import threading
from typing import Callable, Protocol, runtime_checkable

FireFn = Callable[[dict], None]

@runtime_checkable
class Listener(Protocol):
    def start(self) -> None:
        ...
    def stop(self) -> None:
        ...

class PollingListener:
    def __init__(self, config: dict, fire: FireFn) -> None:
        self.config = config
        self.fire = fire
        self._thread: threading.Thread | None = None
        self._stop = threading.Event()
        self.interval = 1.0

    def start(self) -> None:
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()

    def stop(self) -> None:
        self._stop.set()
        if (self._thread):
            self._thread.join(timeout=2)

    def setup(self) -> None: ...
    def poll(self) -> None: ...
    def teardown(self) -> None: ...

    def _loop(self) -> None:
        self.setup()
        while not self._stop.is_set():
            try:
                self.poll()
            except Exception as e:
                print(f"Error in poll: {e}")
            # Wait between polls instead of busy-looping. _stop.wait returns
            # early when stop() is called, so shutdown stays responsive.
            self._stop.wait(self.interval)
        self.teardown()
