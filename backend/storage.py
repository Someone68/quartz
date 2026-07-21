import json
from datetime import datetime
from pathlib import Path
from typing import Annotated

from models import RunLog, Shortcut, ShortcutSummary, Step, TriggerDef
from pydantic.type_adapter import TypeAdapter

CONFIG_DIR = Path("~/.config/quartz").expanduser()
SHORTCUTS_DIR = CONFIG_DIR / "shortcuts"
RUNS_DIR = CONFIG_DIR / "runs"
ACTIONS_CACHE = CONFIG_DIR / "actions_cache.json"
TRIGGERS_CACHE = CONFIG_DIR / "triggers_cache.json"

StepAdapter = TypeAdapter(Step)


def _ensure_dirs():
    SHORTCUTS_DIR.mkdir(parents=True, exist_ok=True)
    RUNS_DIR.mkdir(parents=True, exist_ok=True)


def load_all_shortcut_summaries() -> list[ShortcutSummary]:
    _ensure_dirs()
    summaries = []
    for file in SHORTCUTS_DIR.glob("*.json"):
        try:
            data = json.loads(file.read_text())
            summaries.append(
                ShortcutSummary(
                    id=data["id"],
                    name=data["name"],
                    icon=data.get("icon"),
                    step_count=len(data.get("steps", [])),
                )
            )
        except Exception as e:
            print(f"Failed to load shortcut {file}: {e}")
    return summaries


def save_run(run: RunLog):
    run_dir = RUNS_DIR / datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    run_dir.mkdir(parents=True, exist_ok=True)
    path = run_dir / f"{run.id}.json"
    path.write_text(run.model_dump_json(indent=2))


def load_shortcut(shortcut_id: str) -> Shortcut | None:
    path = SHORTCUTS_DIR / f"{shortcut_id}.json"
    if not path.exists():
        return None
    data = json.loads(path.read_text())
    data["steps"] = [
        StepAdapter.validate_python(step) for step in data.get("steps", [])
    ]
    return Shortcut.model_validate(data)


def save_shortcut(shortcut: Shortcut):
    _ensure_dirs()
    shortcut.updated_at = datetime.utcnow()
    path = SHORTCUTS_DIR / f"{shortcut.id}.json"
    path.write_text(shortcut.model_dump_json(indent=2, by_alias=True))


def delete_shortcut(shortcut_id: str):
    path = SHORTCUTS_DIR / f"{shortcut_id}.json"
    path.unlink(missing_ok=True)


def load_runs(shortcut_id: str) -> list[RunLog]:
    run_dir = RUNS_DIR / shortcut_id
    if not run_dir.exists():
        return []
    runs = []
    for f in sorted(run_dir.glob("*.json"), reverse=True):
        try:
            runs.append(RunLog.model_validate_json(f.read_text()))
        except Exception as e:
            print(f"Failed to load run {f.name}: {e}")
    return runs


def load_run(shortcut_id: str, run_id: str) -> RunLog | None:
    path = RUNS_DIR / shortcut_id / f"{run_id}.json"
    if not path.exists():
        return None
    return RunLog.model_validate_json(path.read_text())


def save_actions_cache(actions_by_category: dict) -> None:
    """Write the action defs (grouped by category) to a cache file the UI
    reads on startup, so it does not depend on a running backend."""
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    ACTIONS_CACHE.write_text(json.dumps(actions_by_category, indent=2))


def save_triggers_cache(triggers: dict[str, TriggerDef]) -> None:
    """Write the trigger defs to a cache file the UI reads on startup."""
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    TRIGGERS_CACHE.write_text(json.dumps(triggers, indent=2))
