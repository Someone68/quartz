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


# --- Boot sweep flag ---
# Set only while trigger_manager registers listeners at process start.
# register() also runs on every shortcut create/edit/rename, and an edit is
# not a program start, so a trigger that fires on start() must check this
# before firing.
_booting = threading.Event()


def booting() -> bool:
    return _booting.is_set()


def set_booting(value: bool) -> None:
    if value:
        _booting.set()
    else:
        _booting.clear()


# --- Shared polling infrastructure ---
# Many shortcuts can share the same polling trigger (e.g. 10 clipboard
# watchers, or 10 app-open watchers). One thread each means N identical
# expensive reads per second. Instead we run ONE background thread per
# dedup key: it samples the source once per interval and fans the sample
# out to every subscriber, each of which runs its own cheap change
# detection. So the process scan / clipboard read happens once, not N times.


class _SharedPoller:
    def __init__(self, sample_fn: Callable[[], object], interval: float) -> None:
        self._sample_fn = sample_fn
        self._interval = interval
        self._subs: dict[int, Callable[[object], None]] = {}
        self._lock = threading.Lock()
        self._stop = threading.Event()
        self._thread: threading.Thread | None = None

    def add(self, sub_id: int, on_sample: Callable[[object], None]) -> None:
        with self._lock:
            self._subs[sub_id] = on_sample
            if self._thread is None:
                self._thread = threading.Thread(target=self._loop, daemon=True)
                self._thread.start()

    def remove(self, sub_id: int) -> bool:
        """Drop a subscriber. Returns True if the poller is now empty
        (caller stops the thread and drops the poller)."""
        with self._lock:
            self._subs.pop(sub_id, None)
            if self._subs:
                return False
            self._stop.set()
            return True

    def _loop(self) -> None:
        while not self._stop.is_set():
            try:
                sample = self._sample_fn()
            except Exception as e:
                print(f"Error sampling poll source: {e}")
            else:
                with self._lock:
                    subs = list(self._subs.values())
                for cb in subs:
                    try:
                        cb(sample)
                    except Exception as e:
                        print(f"Error in poll subscriber: {e}")
            # Wait between polls instead of busy-looping. _stop.wait returns
            # early when stop() is called, so shutdown stays responsive.
            self._stop.wait(self._interval)


_pollers: dict[object, _SharedPoller] = {}
_pollers_lock = threading.Lock()
_sub_seq = 0


class PollingListener:
    """Base for poll-driven triggers. Subclasses override:

    - ``sample()`` (staticmethod): the expensive shared read, run once per
      interval and shared across all listeners with the same dedup key.
    - ``detect(sample)``: cheap per-listener change detection; call
      ``self.fire(...)`` when the trigger condition is met.
    - ``dedup_key()`` (optional): identifies the shared poll source.
      Defaults to (class name, interval) so identical listeners coalesce.
    """

    def __init__(self, config: dict, fire: FireFn) -> None:
        self.config = config
        self.fire = fire
        self.interval = 1.0
        self._sub_id: int | None = None
        self._key: object | None = None

    def setup(self) -> None: ...
    def teardown(self) -> None: ...

    @staticmethod
    def sample() -> object:
        return None

    def detect(self, sample: object) -> None: ...

    def dedup_key(self) -> object:
        return (type(self).__name__, self.interval)

    def start(self) -> None:
        global _sub_seq
        self.setup()
        self._key = self.dedup_key()
        with _pollers_lock:
            poller = _pollers.get(self._key)
            if poller is None:
                poller = _SharedPoller(type(self).sample, self.interval)
                _pollers[self._key] = poller
            _sub_seq += 1
            self._sub_id = _sub_seq
            poller.add(self._sub_id, self._on_sample)

    def _on_sample(self, sample: object) -> None:
        try:
            self.detect(sample)
        except Exception as e:
            print(f"Error in poll: {e}")

    def stop(self) -> None:
        join_thread: threading.Thread | None = None
        with _pollers_lock:
            poller = _pollers.get(self._key)
            if poller is not None and self._sub_id is not None:
                if poller.remove(self._sub_id):
                    # Empty: drop it so a later listener starts a fresh thread.
                    if _pollers.get(self._key) is poller:
                        del _pollers[self._key]
                    join_thread = poller._thread
        if join_thread is not None:
            join_thread.join(timeout=2)
        self.teardown()
