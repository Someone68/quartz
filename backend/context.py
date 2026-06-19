import os
import platform
from typing import Any

from jinja2 import Environment, Undefined
from simpleeval import simple_eval

_jinja = Environment(undefined=Undefined)


def build_context(trigger_meta: dict) -> dict:
    return {
        "trigger": trigger_meta,
        "steps": {},
        "variables": {},
        "env": dict(os.environ),
        "platform": platform.system().lower(),
    }


# ai did this
def resolve(value: Any, context: dict) -> Any:
    if not isinstance(value, str):
        return value
    if "{{" not in value:
        return value
    try:
        template = _jinja.from_string(value)
        return template.render(**context)
    except Exception:
        return value


# this too
def evaluate_condition(expr: str, context: dict) -> bool:
    """Evaluate a condition string safely. Supports basic comparisons and 'contains'."""
    resolved = resolve(expr, context)
    # preprocess "contains" keyword
    resolved = resolved.replace(" contains ", " in ")
    try:
        return bool(simple_eval(resolved))
    except Exception as e:
        raise ValueError(f"Invalid condition '{expr}': {e}")
