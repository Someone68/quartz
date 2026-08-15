import json
import re
from datetime import datetime
from pathlib import Path
from typing import Annotated

import config
from models import (
    DEFAULT_SHORTCUT_COLOR,
    RunLog,
    Shortcut,
    ShortcutSummary,
    Step,
    TriggerDef,
)
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
                    # Shortcuts saved before `color` existed have no key.
                    color=data.get("color", DEFAULT_SHORTCUT_COLOR),
                    step_count=len(data.get("steps", [])),
                )
            )
        except Exception as e:
            print(f"Failed to load shortcut {file}: {e}")
    return summaries


def save_run(run: RunLog):
    """Write (or overwrite) one run log under its shortcut.

    The path must depend only on ids: the executor saves once when the run
    starts and again when it finishes, so a clock-derived path would leave the
    stale "running" copy behind instead of replacing it.
    """
    run_dir = RUNS_DIR / run.shortcut_id
    run_dir.mkdir(parents=True, exist_ok=True)
    path = run_dir / f"{run.id}.json"
    path.write_text(run.model_dump_json(indent=2))
    _prune_runs(run_dir)


def _prune_runs(run_dir: Path) -> None:
    """Drop the oldest logs past run_history_limit (0 = keep everything)."""
    limit = config.get_config().run_history_limit
    if limit <= 0:
        return
    files = sorted(
        run_dir.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True
    )
    for stale in files[limit:]:
        stale.unlink(missing_ok=True)


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
    for f in run_dir.glob("*.json"):
        try:
            runs.append(RunLog.model_validate_json(f.read_text()))
        except Exception as e:
            print(f"Failed to load run {f.name}: {e}")
    # Run ids are uuid4, so filename order says nothing about time.
    runs.sort(key=lambda r: r.started_at, reverse=True)
    return runs


def load_run(shortcut_id: str, run_id: str) -> RunLog | None:
    path = RUNS_DIR / shortcut_id / f"{run_id}.json"
    if not path.exists():
        return None
    return RunLog.model_validate_json(path.read_text())


_LEGACY_RUN_DIR = re.compile(r"^\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}$")


def migrate_runs() -> None:
    """Move run logs out of the old runs/<timestamp>/ layout into
    runs/<shortcut_id>/, where load_runs looks for them.

    Oldest directory first, so where a run was saved twice (once "running",
    once finished) the finished copy is the one that survives.
    """
    if not RUNS_DIR.exists():
        return
    legacy = sorted(
        d for d in RUNS_DIR.iterdir() if d.is_dir() and _LEGACY_RUN_DIR.match(d.name)
    )
    moved = 0
    for old_dir in legacy:
        for f in old_dir.glob("*.json"):
            try:
                run = RunLog.model_validate_json(f.read_text())
            except Exception as e:
                print(f"Skipping unreadable run {f}: {e}")
                continue
            dest_dir = RUNS_DIR / run.shortcut_id
            dest_dir.mkdir(parents=True, exist_ok=True)
            f.replace(dest_dir / f"{run.id}.json")
            moved += 1
        try:
            old_dir.rmdir()
        except OSError:
            print(f"Left {old_dir} in place, it still has files.")
    if moved:
        print(f"Migrated {moved} run logs to the per-shortcut layout.")


def save_actions_cache(actions_by_category: dict) -> None:
    """Write the action defs (grouped by category) to a cache file the UI
    reads on startup, so it does not depend on a running backend."""
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    ACTIONS_CACHE.write_text(json.dumps(actions_by_category, indent=2))


def save_triggers_cache(triggers: dict[str, TriggerDef]) -> None:
    """Write the trigger defs to a cache file the UI reads on startup."""
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    TRIGGERS_CACHE.write_text(json.dumps(triggers, indent=2))
