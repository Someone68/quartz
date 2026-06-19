import importlib.util
from pathlib import Path

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
