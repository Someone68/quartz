import ast
import os
import platform
from typing import Any

from jinja2 import Undefined
from jinja2.nativetypes import NativeEnvironment
from simpleeval import EvalWithCompoundTypes

class _ContextEnvironment(NativeEnvironment):
    """NativeEnvironment that looks up "a.b" as a["b"] before a.b.

    Jinja tries the attribute first, so every context namespace being a plain
    dict meant a variable named after a dict method was shadowed by it:
    {{variables.items}} handed back the bound dict.items method instead of the
    user's list. Same for keys, values, get, pop, count, update.
    """

    def getattr(self, obj, attribute):
        try:
            return obj[attribute]
        except (TypeError, LookupError):
            return super().getattr(obj, attribute)


# NativeEnvironment keeps Python types: a value that is a single "{{ expr }}"
# resolves to the real object (int/bool/list/dict), not its str repr. Mixed
# text like "count is {{ x }}" still renders to a str.
_jinja = _ContextEnvironment(undefined=Undefined)


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


def evaluate(value: Any, names: dict | None = None) -> Any:
    """Evaluate a resolved value as a small expression, returning it unchanged
    when it is not one.

    Two things the plain simple_eval() this replaced got wrong: it rejects
    list/dict/tuple literals outright, so "[1, 2, 3]" could never become a
    list, and it raises on ordinary text, so a variable set to "hello" or
    "apple, banana" failed instead of staying a value. Text is a value here;
    coerce() decides what to make of it.
    """
    if not isinstance(value, str):
        return value
    stripped = value.strip()
    if not stripped:
        return value
    try:
        return EvalWithCompoundTypes(names=names or {}).eval(stripped)
    except Exception:
        return value


def coerce(value: Any, var_type: str) -> Any:
    """Cast a resolved value to a declared variable type so it can be
    manipulated downstream (arithmetic, iteration, boolean logic)."""
    if var_type == "auto":
        return _infer(value)
    if var_type == "string":
        return value if isinstance(value, str) else _to_str(value)
    if var_type == "number":
        if isinstance(value, bool):
            return int(value)
        if isinstance(value, (int, float)):
            return value
        s = str(value).strip()
        f = float(s)
        return int(f) if f.is_integer() and "." not in s and "e" not in s.lower() else f
    if var_type == "boolean":
        if isinstance(value, bool):
            return value
        if isinstance(value, (int, float)):
            return bool(value)
        return str(value).strip().lower() in ("true", "1", "yes", "on")
    if var_type == "list":
        if isinstance(value, list):
            return value
        if isinstance(value, (tuple, set)):
            return list(value)
        return _infer_list(value)
    raise ValueError(f"Unknown variable type: {var_type}")


def _to_str(value: Any) -> str:
    return "" if value is None else str(value)


def _infer(value: Any) -> Any:
    """Best-effort native type from a string; non-strings pass through."""
    if not isinstance(value, str):
        return value
    s = value.strip()
    try:
        return ast.literal_eval(s)
    except (ValueError, SyntaxError):
        return value


def _infer_list(value: Any) -> list:
    parsed = _infer(value)
    if isinstance(parsed, list):
        return parsed
    if isinstance(parsed, (tuple, set)):
        return list(parsed)
    # fall back to comma-separated split
    s = str(value).strip()
    if not s:
        return []
    return [p.strip() for p in s.split(",")]


# this too
def evaluate_condition(expr: str, context: dict) -> bool:
    """Evaluate a condition string safely. Supports basic comparisons and 'contains'."""
    resolved = resolve(expr, context)
    if not isinstance(resolved, str):
        # pure "{{ ... }}" already resolved to a native value; use its truthiness
        return bool(resolved)
    # preprocess "contains" keyword
    resolved = resolved.replace(" contains ", " in ")
    try:
        # Compound types so membership tests against literals work:
        # "'a' in ['a', 'b']" is rejected by the base evaluator.
        return bool(EvalWithCompoundTypes().eval(resolved))
    except Exception as e:
        raise ValueError(f"Invalid condition '{expr}': {e}")
