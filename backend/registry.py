import importlib.util
from pathlib import Path

import storage
from models import ActionDef

_registry: dict[str, ActionDef] = {}


def load_all():
    actions_dir = Path(__file__).parent / "actions"
    for path in sorted(actions_dir.rglob("*.py")):
        if path.name.startswith("_"):
            continue
        try:
            spec = importlib.util.spec_from_file_location(path.stem, path)
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)
            if hasattr(mod, "ACTION"):
                action: ActionDef = mod.ACTION
                _registry[action.id] = action
                print(f"  registered action: {action.id}")
        except Exception as e:
            print(f"  failed to load action {path}: {e}")
    _write_cache()


def _write_cache():
    """Persist action defs to the UI cache. Called on every (re)load."""
    try:
        data = {
            cat: [a.model_dump(mode="json") for a in defs]
            for cat, defs in all_actions_by_category().items()
        }
        storage.save_actions_cache(data)
    except Exception as e:
        print(f"  failed to write actions cache: {e}")


def get(action_id: str) -> ActionDef:
    if action_id not in _registry:
        raise KeyError(f"Unknown action: {action_id}")
    return _registry[action_id]


def all_actions() -> list[ActionDef]:
    return list(_registry.values())


def all_actions_by_category() -> dict[str, list[ActionDef]]:
    result: dict[str, list[ActionDef]] = {}
    for action in _registry.values():
        result.setdefault(action.category, []).append(action)
    return result
