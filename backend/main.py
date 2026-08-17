import io
import os
import secrets
import sys
from contextlib import asynccontextmanager

import config
import executor
import get_apps
import get_brightness
import paths
import registry
import runtime
import storage
import tray
import trigger_manager
import trigger_registry
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from get_apps import launch_by_name, load_apps
from models import Shortcut
from pydantic import BaseModel
from version import __version__

# unvicorn sucks so we need this on windows
if sys.stdout is None:
    sys.stdout = io.StringIO()
if sys.stderr is None:
    sys.stderr = io.StringIO()


class RenameRequest(BaseModel):
    name: str


@asynccontextmanager
async def lifespan(app: FastAPI):
    cfg = config.get_config()
    print(f"Config loaded from {config.CONFIG_PATH}")
    # Publish the handshake so the UI can find us. Port and token are chosen in
    # __main__ (or on first import when run without it) and passed via env so
    # they survive uvicorn's reloader spawning a child process.
    token = os.environ.get("QUARTZ_TOKEN") or runtime.new_token()
    port = int(os.environ.get("QUARTZ_PORT", cfg.port))
    runtime.set_token(token)
    runtime.write(cfg.host, port, token)
    print(f"Handshake written to {runtime.RUNTIME_PATH} (port {port})")
    storage.migrate_runs()
    print("Loading actions...")
    registry.load_all()
    print(f"Loaded {len(registry.all_actions())} actions.")
    print("Loading triggers...")
    trigger_registry.load_all()
    print(f"Loaded {len(trigger_registry.all_triggers())} triggers.")
    print("Starting trigger listeners...")
    trigger_manager.start_all()
    get_brightness.prewarm()
    tray.start(port)
    yield
    trigger_manager.stop_all()
    runtime.remove()


app = FastAPI(title="Quartz Backend", lifespan=lifespan)

# No CORS middleware on purpose: the Flutter desktop client uses dart:io and
# is not subject to CORS, while a permissive policy would let any website the
# user visits drive this API from their browser.

# Paths reachable without the auth token: only the discovery probe the UI hits
# before it has read the token from the handshake file.
_PUBLIC_PATHS = {"/health"}


@app.middleware("http")
async def require_token(request: Request, call_next):
    """Gate every request on the per-run Bearer token.

    Loopback binding already blocks the network; this stops other local users
    (who can also reach 127.0.0.1) from driving an API that runs shell commands.
    """
    if request.url.path not in _PUBLIC_PATHS:
        expected = runtime.get_token()
        presented = request.headers.get("Authorization", "")
        if not expected or not secrets.compare_digest(presented, f"Bearer {expected}"):
            return JSONResponse({"detail": "Unauthorized"}, status_code=401)
    return await call_next(request)


@app.get("/health")
def health():
    """Unauthenticated liveness probe used by the UI to discover the daemon."""
    return {"status": "ok", "version": __version__}


@app.get("/shortcuts")
def list_shortcuts():
    return storage.load_all_shortcut_summaries()


@app.post("/shortcuts", status_code=201)
def create_shortcut(shortcut: Shortcut):
    storage.save_shortcut(shortcut)
    trigger_manager.refresh(shortcut)
    return shortcut


@app.get("/shortcuts/{shortcut_id}")
def get_shortcut(shortcut_id: str):
    shortcut = storage.load_shortcut(shortcut_id)
    if not shortcut:
        raise HTTPException(status_code=404, detail="Shortcut not found")
    return shortcut


@app.put("/shortcuts/{shortcut_id}")
def update_shortcut(shortcut_id: str, shortcut: Shortcut):
    existing_shortcut = storage.load_shortcut(shortcut_id)
    if not existing_shortcut:
        raise HTTPException(status_code=404, detail="Shortcut not found")
    shortcut.id = shortcut_id
    storage.save_shortcut(shortcut)
    trigger_manager.refresh(shortcut)
    return shortcut


@app.patch("/shortcuts/{shortcut_id}/rename")
def rename_shortcut(shortcut_id: str, body: RenameRequest):
    shortcut = storage.load_shortcut(shortcut_id)
    if not shortcut:
        raise HTTPException(status_code=404, detail="Shortcut not found")
    shortcut.name = body.name
    storage.save_shortcut(shortcut)
    trigger_manager.refresh(shortcut)
    return shortcut


@app.delete("/shortcuts/{shortcut_id}", status_code=204)
def delete_shortcut(shortcut_id: str):
    storage.delete_shortcut(shortcut_id)
    trigger_manager.unregister(shortcut_id)


@app.post("/shortcuts/{shortcut_id}/run")
def run_shortcut(shortcut_id: str):
    s = storage.load_shortcut(shortcut_id)
    if not s:
        raise HTTPException(404, "Shortcut not found")
    run = executor.run_shortcut(s, trigger_meta={"type": "manual"})
    return run


@app.get("/shortcuts/{shortcut_id}/runs")
def list_runs(shortcut_id: str):
    return storage.load_runs(shortcut_id)


@app.get("/shortcuts/{shortcut_id}/runs/{run_id}")
def get_run(shortcut_id: str, run_id: str):
    run = storage.load_run(shortcut_id, run_id)
    if not run:
        raise HTTPException(404, "Run not found")
    return run


@app.get("/config")
def get_config():
    return config.get_config()


@app.put("/config")
def update_config(cfg: config.AppConfig):
    config.save_config(cfg)
    return config.reload_config()


@app.get("/actions")
def list_actions():
    return registry.all_actions_by_category()


@app.get("/triggers")
def list_triggers():
    return trigger_registry.all_triggers()


@app.post("/launch-by-name")
def launch_app_by_name(req: get_apps.LaunchByName):
    try:
        return launch_by_name(req.name)
    except LookupError as e:
        raise HTTPException(404, str(e))


@app.get("/apps")
def list_apps():
    return {"apps": load_apps()}


if __name__ == "__main__":
    import uvicorn

    cfg = config.get_config()
    # config.port is the *preferred* port; fall back to an OS-chosen free port
    # if it is taken so a second daemon (or a leftover) can't wedge startup.
    port = runtime.find_free_port(cfg.host, cfg.port)
    # Hand the chosen port and a fresh token to the serving process via env.
    # With reload=True uvicorn runs the app in a child process, so a module
    # global would not reach the lifespan; the environment does.
    os.environ["QUARTZ_PORT"] = str(port)
    os.environ.setdefault("QUARTZ_TOKEN", secrets.token_urlsafe(32))
    # A frozen build has no importable "main" module and cannot fork a
    # reloader child, so hand uvicorn the app object and keep reload off.
    uvicorn.run(
        app if paths.IS_FROZEN else "main:app",
        host=cfg.host,
        port=port,
        log_level=cfg.log_level,
        reload=not paths.IS_FROZEN,
    )
