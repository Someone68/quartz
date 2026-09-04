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
import sys
import urllib.request
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


def reserve_port(host: str, preferred: int) -> tuple[socket.socket, int]:
    """Bind ``preferred`` (else an OS-chosen free port) and return the socket.

    The bound socket is returned rather than just the number so the caller can
    hand it straight to uvicorn: closing it first would reopen the window where
    another process takes the port between the probe and the real bind.

    The socket option differs by platform and must not be unified. On POSIX,
    SO_REUSEADDR only waives TIME_WAIT, so the preferred port survives a
    restart while a live listener still blocks the bind. On Windows the same
    option means "bind even if another process is listening here", which would
    hand back a port we cannot serve; SO_EXCLUSIVEADDRUSE is its opposite and
    stops anyone doing that to us.
    """
    for port in (preferred, 0):
        s = socket.socket(_family(host), socket.SOCK_STREAM)
        if sys.platform == "win32":
            s.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
        else:
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            s.bind((host, port))
        except OSError:
            s.close()
            continue
        return s, s.getsockname()[1]
    raise OSError("no free port available")


def _health_url(host: str, port: int) -> str:
    return f"http://{f'[{host}]' if ':' in host else host}:{port}/health"


def read() -> dict | None:
    """Parse runtime.json, or None when it is missing or unreadable."""
    try:
        return json.loads(RUNTIME_PATH.read_text())
    except (OSError, ValueError):
        return None


def _pid_alive(pid: int) -> bool:
    """Best-effort liveness check; True when we cannot tell."""
    try:
        import psutil

        return psutil.pid_exists(pid)
    except Exception:
        return True


def daemon_running() -> bool:
    """True when a daemon started earlier is still serving.

    Single-instance guard. The UI spawns a daemon whenever its health probe
    times out and Windows autostart launches one at logon, so two can race.
    A second daemon must not get as far as writing the handshake: it would
    publish a token it never serves (the lifespan runs before uvicorn binds),
    leaving the UI with a token the live daemon rejects with 401.

    A stale runtime.json (daemon killed without cleanup) fails the health probe
    and returns False, so a genuine restart is never blocked.
    """
    data = read()
    if not data:
        return False
    pid, host, port = data.get("pid"), data.get("host"), data.get("port")
    if isinstance(pid, int) and not _pid_alive(pid):
        return False
    if not host or not port:
        return False
    # No proxies: this is a loopback probe, and an http_proxy in the
    # environment would otherwise route it (and could answer for us).
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    try:
        with opener.open(_health_url(host, int(port)), timeout=1.0) as res:
            body = json.loads(res.read(4096))
    except Exception:
        return False
    # Confirm it is a Quartz daemon answering, not whatever else took the port.
    return body.get("status") == "ok" and "version" in body


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
