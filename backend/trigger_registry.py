import importlib.util
from pathlib import Path

from models import TriggerDef

_registry: dict[str, TriggerDef] = {}


def load_all():
    triggers_dir = Path(__file__).parent / "triggers"
    for path in sorted(triggers_dir.glob("*.py")):
        if path.name.startswith("_"):
            continue
        try:
            spec = importlib.util.spec_from_file_location(path.stem, path)
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)
            if hasattr(mod, "TRIGGER"):
                trigger: TriggerDef = mod.TRIGGER
                _registry[trigger.type] = trigger
                print(f"  registered trigger: {trigger.type}")
        except Exception as e:
            print(f"  failed to load trigger {path}: {e}")


def get(trigger_type: str) -> TriggerDef:
    if trigger_type not in _registry:
        raise KeyError(f"Unknown trigger: {trigger_type}")
    return _registry[trigger_type]


def all_triggers() -> list[TriggerDef]:
    return list(_registry.values())
