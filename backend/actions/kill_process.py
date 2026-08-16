import psutil
from models import ActionDef, ActionInput, ActionOutput


def to_pid(value) -> int:
    # Arrives as text (typed into the field, or a resolved template), and may be
    # "1234.0" when a template resolves a number.
    try:
        pid = int(str(value).strip())
    except (TypeError, ValueError):
        try:
            pid = int(float(str(value).strip()))
        except (TypeError, ValueError):
            raise ValueError(f"Cannot end process: {value!r} is not a process ID")
    if pid <= 0:
        raise ValueError(f"Cannot end process: {pid} is not a process ID")
    return pid


# By PID
def kill_pid(pid, force=False):
    p = psutil.Process(to_pid(pid))
    p.kill() if force else p.terminate()
    p.wait(timeout=5)


# By name
def kill_by_name(name, force=False):
    killed = []
    for p in psutil.process_iter(["name"]):
        if p.info["name"] != name:
            continue
        try:
            (p.kill if force else p.terminate)()
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            # One process we can't signal shouldn't abort the remaining matches.
            continue
        killed.append(p)
    gone, _alive = psutil.wait_procs(killed, timeout=5)
    return [p.pid for p in gone]


def _run(inputs: dict, context: dict) -> dict:
    mode = inputs.get("mode")
    name = str(inputs.get("name")).lower()
    name_alt = inputs.get("name_alt")
    pid = inputs.get("pid")
    force = inputs.get("force", False)
    error = inputs.get("error", False)

    if mode == "PID":
        target = to_pid(pid)
        try:
            kill_pid(target, force)
        except psutil.NoSuchProcess:
            if error:
                raise RuntimeError(f"Cannot end process: process not found: {target}")
            return {"killed": False, "count": 0}
        except psutil.AccessDenied:
            if error:
                raise RuntimeError(f"Cannot end process {target}: access denied")
            return {"killed": False, "count": 0}
        except psutil.TimeoutExpired:
            if error:
                raise RuntimeError(
                    f"Cannot end process {target}: still running after 5s"
                    + ("" if force else "; try Force")
                )
            return {"killed": False, "count": 0}
        return {"killed": True, "count": 1}

    if mode == "Name":
        target = name_alt or name
        if not target:
            raise ValueError("Cannot end process: no process name given")
        killed = kill_by_name(target, force)
        if not killed and error:
            raise RuntimeError(f"Cannot end process: process not found: {target}")
        return {"killed": bool(killed), "count": len(killed)}

    raise ValueError(f"Cannot end process: unknown method {mode!r}")


ACTION = ActionDef(
    id="system.kill_process",
    category="System",
    name="Kill Process",
    description="Kill a process. Can be used to close an application or program.",
    icon="cancel",
    color="amber",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(
            name="mode",
            type="choice",
            label="Method",
            required=True,
            tooltip="The method to use for killing the process.",
            options=["PID", "Name"],
            default="Name",
        ),
        ActionInput(
            name="force",
            type="boolean",
            label="Force",
            required=False,
            tooltip="Terminate the process forcefully.",
            default=False,
        ),
        ActionInput(
            name="name",
            type="app",
            label="Process name",
            required=False,
            tooltip="The process name to kill.",
            requires={"mode": "Name"},
        ),
        ActionInput(
            name="name_alt",
            type="string",
            label="Process name (alternative)",
            required=False,
            tooltip="The process name to kill. Use if process is not available from the app list. This will take priority over the app list.",
            requires={"mode": "Name"},
        ),
        ActionInput(
            name="pid",
            type="number",
            label="Process ID",
            required=True,
            tooltip="The process ID to kill.",
            requires={"mode": "PID"},
            default="",
        ),
        ActionInput(
            name="error",
            type="boolean",
            label="Throw error if failed",
            required=False,
            tooltip="Throw an error if the process fails to kill.",
            default=False,
        ),
    ],
    outputs=[
        ActionOutput(name="killed", type="boolean", label="Killed"),
        ActionOutput(name="count", type="number", label="Processes killed"),
    ],
    run=_run,
)
