# fix for the dialogs and stuff

import os
import sys

_HIJACKED = (
    "LD_LIBRARY_PATH",
    "DYLD_LIBRARY_PATH",
    "LIBPATH",
    "SSL_CERT_FILE",
    "GTK_PATH",
    "GTK_EXE_PREFIX",
    "GTK_DATA_PREFIX",
    "GDK_PIXBUF_MODULE_FILE",
    "GDK_PIXBUF_MODULEDIR",
    "GI_TYPELIB_PATH",
    "TCL_LIBRARY",
    "TK_LIBRARY",
)

FROZEN = getattr(sys, "frozen", False)


def clean_env(extra: dict | None = None) -> dict:
    """A copy of the environment safe to hand to a non-bundled program."""
    env = dict(os.environ)
    if FROZEN:
        for var in _HIJACKED:
            original = env.pop(var + "_ORIG", None)
            if original:
                env[var] = original
            else:
                env.pop(var, None)
        env.pop("_MEIPASS2", None)
    if extra:
        env.update(extra)
    return env


# Dynamic linker failures: the child never ran, whatever its exit code says.
_LOADER_ERRORS = (
    "error while loading shared libraries",
    "cannot open shared object file",
    "symbol lookup error",
    "not found (required by",
    "undefined symbol",
)


def launch_failed(stderr: str | None) -> str | None:
    """First line of a linker failure in `stderr`, or None if it ran fine.

    Exit codes cannot tell these apart from a legitimate refusal — zenity's
    dynamic-link failure and its "user pressed Cancel" are both exit 1 — so the
    check reads stderr instead.
    """
    if not stderr:
        return None
    for line in stderr.splitlines():
        if any(marker in line for marker in _LOADER_ERRORS):
            return line.strip()
    return None
