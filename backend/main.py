from contextlib import asynccontextmanager

import executor
import registry
import storage
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from models import Shortcut


@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Loading actions...")
    registry.load_all()
    print(f"Loaded {len(registry.all_actions())} actions.")
    yield


app = FastAPI(title="Quartz Backend", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/shortcuts")
def list_shortcuts():
    return storage.load_all_shortcut_summaries()


@app.post("/shortcuts", status_code=201)
def create_shortcut(shortcut: Shortcut):
    storage.save_shortcut(shortcut)
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
    return shortcut


@app.delete("/shortcuts/{shortcut_id}")
def delete_shortcut(shortcut_id: str):
    storage.delete_shortcut(shortcut_id)
    return {"message": "Shortcut deleted"}


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


@app.get("/actions")
def list_actions():
    return registry.all_actions_by_category()


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8757, reload=True)
