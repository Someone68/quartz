"""Runtime handshake: how the UI discovers a running daemon.

Written on startup to ``~/.config/quartz/runtime.json`` (mode 0600) and deleted
on clean shutdown. Holds the *actual* bound port (which can differ from the
user's preferred port in config.json), the pid, and a per-run auth token the UI
must present as ``Authorization: Bearer <token>`` on every request. Loopback
plus this token keeps other local users off an API that can run shell commands.
"""

import json
import os
import secrets
import socket
from datetime import datetime, timezone

from config import CONFIG_DIR
from version import __version__

RUNTIME_PATH = CONFIG_DIR / "runtime.json"

# The token for the current process, checked by the auth middleware. Set once at
# startup via set_token(); None means "no token yet" and the middleware rejects
# every non-public request rather than fail open.
_token: str | None = None


def new_token() -> str:
    """Mint a fresh URL-safe token."""
    return secrets.token_urlsafe(32)


def set_token(token: str) -> None:
    global _token
    _token = token


def get_token() -> str | None:
    return _token


def _family(host: str) -> int:
    return socket.AF_INET6 if ":" in host else socket.AF_INET


def find_free_port(host: str, preferred: int) -> int:
    """Return ``preferred`` if it can be bound, else an OS-chosen free port.

    Probes with a throwaway socket. A different process could grab the port
    between here and uvicorn's own bind, but with one daemon per user on
    loopback that race is negligible.
    """
    for port in (preferred, 0):
        with socket.socket(_family(host), socket.SOCK_STREAM) as s:
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            try:
                s.bind((host, port))
            except OSError:
                continue
            return s.getsockname()[1]
    raise OSError("no free port available")


def write(host: str, port: int, token: str) -> None:
    """Write runtime.json atomically with the token never world-readable."""
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    data = {
        "host": host,
        "port": port,
        "pid": os.getpid(),
        "token": token,
        "version": __version__,
        "started": datetime.now(timezone.utc).isoformat(),
    }
    # Write to a private temp file, then rename, so readers never observe a
    # partially-written file and the token is 0600 from the first byte.
    tmp = RUNTIME_PATH.with_name(RUNTIME_PATH.name + ".tmp")
    tmp.write_text(json.dumps(data, indent=2))
    os.chmod(tmp, 0o600)
    tmp.replace(RUNTIME_PATH)


def remove() -> None:
    try:
        RUNTIME_PATH.unlink()
    except FileNotFoundError:
        pass
