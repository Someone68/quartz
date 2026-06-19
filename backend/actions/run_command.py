import subprocess

from models import ActionDef, ActionInput, ActionOutput


def _run(inputs: dict, context: dict) -> dict:
    command = inputs["command"]
    timeout = inputs.get("timeout", 30)

    result = subprocess.run(
        command,
        shell=True,
        capture_output=True,
        text=True,
        timeout=float(timeout),
    )

    return {
        "stdout": result.stdout.strip(),
        "stderr": result.stderr.strip(),
        "exit_code": result.returncode,
    }


ACTION = ActionDef(
    id="shell.run_command",
    category="Shell",
    name="Run Command",
    description="Run a shell command and capture its output.",
    icon="terminal",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(name="command", type="string", label="Command", required=True),
        ActionInput(
            name="timeout",
            type="number",
            label="Timeout (seconds)",
            required=False,
            default=30,
            min=1,
            max=300,
        ),
    ],
    outputs=[
        ActionOutput(name="stdout", type="string", label="Standard output"),
        ActionOutput(name="stderr", type="string", label="Standard error"),
        ActionOutput(name="exit_code", type="number", label="Exit code"),
    ],
    run=_run,
)
