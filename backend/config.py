import json
from pathlib import Path

from pydantic import BaseModel

CONFIG_DIR = Path("~/.config/quartz").expanduser()
CONFIG_PATH = CONFIG_DIR / "config.json"


class AppConfig(BaseModel):
    """User-facing backend settings, persisted to config.json.

    Add new fields here with a default; old config files stay valid and
    missing keys fall back to the default automatically.
    """

    # Loopback only. The API is unauthenticated and can run arbitrary shell
    # commands, so binding a routable address exposes the machine to anyone
    # on the network. Do not widen this without adding auth.
    host: str = "127.0.0.1"
    port: int = 8757
    log_level: str = "info"
    # How many run logs to keep per shortcut (0 = unlimited).
    run_history_limit: int = 100
    # Poll interval (seconds) for triggers that poll (clipboard, network, etc).
    poll_interval: float = 1.0

    dialog_backend: str = ""


_config: AppConfig | None = None


def load_config() -> AppConfig:
    """Read config.json, creating it with defaults if missing. Unknown keys
    are ignored; missing keys use model defaults."""
    if CONFIG_PATH.exists():
        try:
            cfg = AppConfig.model_validate_json(CONFIG_PATH.read_text())
        except Exception as e:
            print(f"Bad config.json ({e}); using defaults.")
            cfg = AppConfig()
    else:
        cfg = AppConfig()
    # Write back so the file exists and gains any newly-added default keys.
    save_config(cfg)
    if cfg.host not in ("127.0.0.1", "localhost", "::1"):
        print(
            f"WARNING: host is {cfg.host!r}, not loopback. The API has no "
            f"authentication and can run shell commands, so anyone who can "
            f"reach this machine can control it. Set host to 127.0.0.1 in "
            f"{CONFIG_PATH}."
        )
    return cfg


def save_config(cfg: AppConfig) -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    CONFIG_PATH.write_text(cfg.model_dump_json(indent=2))


def get_config() -> AppConfig:
    """Return the cached config, loading it on first access."""
    global _config
    if _config is None:
        _config = load_config()
    return _config


def reload_config() -> AppConfig:
    """Force re-read from disk (e.g. after external edit)."""
    global _config
    _config = load_config()
    return _config
