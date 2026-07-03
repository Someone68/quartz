import os
import platform
from typing import Any

from jinja2 import Environment, Undefined
from simpleeval import simple_eval

_MISSING = object()


def _lookup(path: str, context: dict) -> Any:
    """Resolve a dotted path against the context, falling back to a bare name
    in `variables`. Returns _MISSING if not found."""
    parts = path.split(".")
    # bare single name -> variables[name]
    if len(parts) == 1 and parts[0] not in context and parts[0] in context.get(
        "variables", {}
    ):
        return context["variables"][parts[0]]
    cur: Any = context
    for p in parts:
        if isinstance(cur, dict) and p in cur:
            cur = cur[p]
        else:
            return _MISSING
    return cur


def format_string(template: str, context: dict) -> str:
    """Substitute `{name}` placeholders with values from the context.

    - `{name}` is replaced by the resolved value (dotted paths allowed, e.g.
      `{steps.s1.output}`; a bare name falls back to `variables[name]`).
    - `\\{name}` is emitted literally as `{name}`; the backslash is consumed and
      no substitution happens.
    - An unknown key is left untouched (`{name}` stays) so it is visible.

    Always returns a string.
    """
    out: list[str] = []
    i = 0
    n = len(template)
    while i < n:
        ch = template[i]
        if ch == "\\" and i + 1 < n and template[i + 1] == "{":
            # escaped brace: emit literal '{', skip the backslash
            out.append("{")
            i += 2
            continue
        if ch == "{":
            end = template.find("}", i + 1)
            if end == -1:
                # no closing brace: emit rest verbatim
                out.append(template[i:])
                break
            key = template[i + 1 : end].strip()
            val = _lookup(key, context)
            if val is _MISSING:
                out.append(template[i : end + 1])  # leave `{key}` as-is
            else:
                out.append(str(val))
            i = end + 1
            continue
        out.append(ch)
        i += 1
    return "".join(out)

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
