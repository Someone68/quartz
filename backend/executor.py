import threading
import time
from datetime import datetime
from locale import format_string

import registry
import storage
from context import build_context, evaluate_condition, resolve
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


class ShortcutStopped(Exception):
    pass


def run_shortcut(shortcut: Shortcut, trigger_meta: dict = {}) -> RunLog:
    context = build_context(trigger_meta)
    steps_by_id = shortcut.steps_by_id()
    top_level_ids = [s.id for s in shortcut.steps]

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
            result = action.run(resolved_inputs, context)
            context["steps"][step.id] = result or {}

        case SetVarStep():
            context["variables"][step.var_name] = resolve(step.value, context)

        case RunShortcutStep():
            nested = storage.load_shortcut(format_string(step.shortcut_id, context))
            if not nested:
                raise ValueError(
                    f"Shortcut not found: {format_string(step.shortcut_id, context)}"
                )
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
                if evaluate_condition(format_string(step.condition, context), context)
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
