import threading
import time
from datetime import datetime

import registry
import storage
from context import build_context, coerce, evaluate_condition, resolve
from models import (
    ActionStep,
    IfStep,
    LoopStep,
    RepeatStep,
    RunLog,
    RunShortcutStep,
    SetVarStep,
    Shortcut,
    Step,
    StopStep,
    WaitStep,
)
from simpleeval import simple_eval


class ShortcutStopped(Exception):
    pass


def run_shortcut(shortcut: Shortcut, trigger_meta: dict = {}) -> RunLog:
    context = build_context(trigger_meta)
    steps_by_id = shortcut.steps_by_id()
    # Every step lives in the flat list; containers reference their children by
    # id. Top-level = steps no container owns, else a branch/body child would
    # also run here at the root.
    child_ids: set[str] = set()
    for s in shortcut.steps:
        if isinstance(s, IfStep):
            child_ids.update(s.then, s.else_)
        elif isinstance(s, (LoopStep, RepeatStep)):
            child_ids.update(s.steps)
    top_level_ids = [s.id for s in shortcut.steps if s.id not in child_ids]

    run = RunLog(
        shortcut_id=shortcut.id,
        started_at=datetime.now(),
        status="running",
    )
    storage.save_run(run)

    try:
        _run_steps(top_level_ids, context, steps_by_id)
        run.status = "success"
    except ShortcutStopped as e:
        run.status = "stopped"
        run.error = str(e)
    except Exception as e:
        run.status = "failed"
        run.error = str(e)
    finally:
        run.finished_at = datetime.now()
        run.step_outputs = context["steps"]
        storage.save_run(run)

    return run


def _run_steps(
    step_ids: list[str], context: dict, steps_by_id: dict[str, Step]
) -> None:
    for step_id in step_ids:
        step = steps_by_id[step_id]
        if step is None:
            raise RuntimeError(f"step {step_id} not found")
        if not step.enabled:
            continue
        _run_step(step, context, steps_by_id)


def _run_step(step: Step, context: dict, steps_by_id: dict[str, Step]) -> None:
    match step:
        case ActionStep():
            action = registry.get(step.action_id)
            resolved_inputs = {k: resolve(v, context) for k, v in step.inputs.items()}
            try:
                result = action.run(resolved_inputs, context)
            except ShortcutStopped:
                raise
            except Exception as e:
                name = step.label or step.action_id
                raise RuntimeError(f"Step '{name} ({step.id})' failed: {e}") from e
            context["steps"][step.id] = result or {}

        case SetVarStep():
            resolved = resolve(step.value, context)
            try:
                context["variables"][step.var_name] = coerce(
                    simple_eval(resolved), step.var_type
                )
            except (ValueError, TypeError) as e:
                raise ValueError(
                    f"Cannot set '{step.var_name}' as {step.var_type}: {resolved!r} ({e})"
                )

        case RunShortcutStep():
            shortcut_id = resolve(step.shortcut_id, context)
            nested = storage.load_shortcut(shortcut_id)
            if not nested:
                raise ValueError(f"Shortcut not found: {shortcut_id}")
            resolved_inputs = {k: resolve(v, context) for k, v in step.inputs.items()}
            nested_trigger_meta = {
                "type": "nested",
                "parent": context["trigger"],
                **resolved_inputs,
            }

            if step.wait:
                nested_run = run_shortcut(nested, nested_trigger_meta)  # recursive call
                context["steps"][step.id] = {
                    "status": nested_run.status,
                    "outputs": nested_run.step_outputs,
                }
                if nested_run.status == "failed":
                    raise RuntimeError(f"Nested shortcut failed: {nested_run.error}")
            else:
                threading.Thread(
                    target=run_shortcut, args=(nested, nested_trigger_meta)
                ).start()

        case IfStep():
            branch = (
                step.then
                if evaluate_condition((step.condition), context)
                else step.else_
            )
            _run_steps(branch, context, steps_by_id)

        case LoopStep():
            items = resolve(step.over, context)
            if not isinstance(items, list):
                raise ValueError(
                    f"Loop 'over' must resolve to a list, got: {type(items)}"
                )
            for item in items:
                context["variables"][step.variable] = item
                _run_steps(step.steps, context, steps_by_id)

        case RepeatStep():
            for _ in range(int(resolve(step.times, context))):
                _run_steps(step.steps, context, steps_by_id)

        case WaitStep():
            time.sleep(float(resolve(step.duration, context)))

        case StopStep():
            msg = resolve(step.message or "", context)
            raise ShortcutStopped(msg)

        case _:
            raise ValueError(f"Unknown step type: {step.type}")
