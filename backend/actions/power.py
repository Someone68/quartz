import os

from models import ActionDef, ActionInput, ActionOutput
import platform, subprocess

def _run(inputs: dict, context: dict) -> dict:
    action = inputs["action"]
    system = platform.system()

    if system == "Windows":
        cmds = {
            "suspend":   ["rundll32.exe", "powrprof.dll,SetSuspendState", "0,1,0"],
            "hibernate": ["shutdown", "/h"],
            "poweroff":  ["shutdown", "/s", "/t", "0"],
            "reboot":    ["shutdown", "/r", "/t", "0"],
            "lock":      ["rundll32.exe", "user32.dll,LockWorkStation"],
            "logout":    ["shutdown", "/l"],
        }
    elif system == "Linux":
        cmds = {
            "suspend":   ["systemctl", "suspend"],
            "hibernate": ["systemctl", "hibernate"],
            "poweroff":  ["systemctl", "poweroff"],
            "reboot":    ["systemctl", "reboot"],
            "lock":      ["loginctl", "lock-session"],
            "logout":    ["loginctl", "terminate-user", os.getlogin()],
        }
    else:
        raise ValueError(system)
    cmd = cmds[action]
    subprocess.run(cmd, check=True)
    return {}


ACTION = ActionDef(
    id="system.power",
    category="System",
    name="Power",
    description="Power management actions.",
    icon="power_settings_new",
    color="amber",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(name="action", type="choice", label="Action", required=True, options=["shutdown", "reboot", "suspend", "hibernate", "lock", "logout"], default="lock"),
    ],
    outputs=[

    ],
    run=_run,
)
