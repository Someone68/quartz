import threading

import executor
import storage
import trigger_registry
from models import Shortcut
from triggers._base import Listener

_listeners: dict[str, Listener] = {}
_lock = threading.Lock()


def _fire_fn(shortcut: Shortcut):
    """Build the fire callback a listener calls when its trigger fires."""

    def fire(payload: dict | None = None):
        meta = {"type": shortcut.trigger.type, **(payload or {})}

        def run():
            try:
                executor.run_shortcut(shortcut, meta)
            except Exception as e:
                print(f"  trigger run failed {shortcut.id}: {e}")

        threading.Thread(target=run, daemon=True).start()

    return fire


def register(shortcut: Shortcut) -> None:
    """Create, start, and store one shortcut's listener. Guards inside."""
    if not shortcut.enabled:
        return
    if shortcut.trigger.type == "manual":
        return

    with _lock:
        if shortcut.id in _listeners:
            print(f"  already registered, skipping: {shortcut.id}")
            return
        try:
            td = trigger_registry.get(shortcut.trigger.type)
            listener = td.make_listener(shortcut.trigger.config, _fire_fn(shortcut))
            listener.start()
            _listeners[shortcut.id] = listener
            print(f"  registered listener: {shortcut.id} ({shortcut.trigger.type})")
        except Exception as e:
            print(f"  failed to register {shortcut.id}: {e}")


def unregister(shortcut_id: str) -> None:
    """Stop and drop one shortcut's listener, if present."""
    with _lock:
        listener = _listeners.pop(shortcut_id, None)
    if listener is None:
        return
    try:
        listener.stop()
        print(f"  unregistered listener: {shortcut_id}")
    except Exception as e:
        print(f"  failed to stop {shortcut_id}: {e}")


def refresh(shortcut: Shortcut) -> None:
    """Re-register after an edit/enable/disable so the listener tracks state."""
    unregister(shortcut.id)
    register(shortcut)


def start_all() -> None:
    """Boot sweep: register every eligible shortcut."""
    for summary in storage.load_all_shortcut_summaries():
        shortcut = storage.load_shortcut(summary.id)
        if shortcut is None:
            print(f"  skip, could not load: {summary.id}")
            continue
        register(shortcut)
    print(f"Registered {len(_listeners)} trigger listeners.")


def stop_all() -> None:
    """Shutdown: stop every listener and clear the registry."""
    with _lock:
        items = list(_listeners.items())
        _listeners.clear()
    for shortcut_id, listener in items:
        try:
            listener.stop()
        except Exception as e:
            print(f"  failed to stop {shortcut_id}: {e}")
