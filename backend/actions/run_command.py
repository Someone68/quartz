import subprocess

from models import ActionDef, ActionInput, ActionOutput


def _run(inputs: dict, context: dict) -> dict:
    command = inputs["command"]
    timeout = inputs.get("timeout", 30)
    willabort = inputs.get("willabort", True)

    result = subprocess.run(
        command,
        shell=True,
        capture_output=True,
        text=True,
        timeout=float(timeout),
    )

    if willabort and result.returncode != 0:
        stderr = result.stderr.strip()
        raise RuntimeError(
            f"Command failed (exit {result.returncode}): {command}"
            + (f"\n{stderr}" if stderr else "")
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
    color="cyan",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(name="command", type="string", label="Command", required=True, tooltip="The shell command to run. Example: `ls -la`"),
        ActionInput(
            name="timeout",
            type="number",
            label="Timeout (seconds)",
            required=False,
            default=30,
            min=1,
            max=300,
            tooltip="Time in seconds the command can run before being timed out."
        ),
        ActionInput(
            name="willabort",
            type="boolean",
            label="Abort on error",
            required=True,
            default=True,
            tooltip="Whether the shortcut should abort if the command returns a non-zero exit code."
        ),
    ],
    outputs=[
        ActionOutput(name="stdout", type="string", label="Standard output. Example: `Hello World!`"),
        ActionOutput(name="stderr", type="string", label="Standard error. Example: `Error: ...`"),
        ActionOutput(name="exit_code", type="number", label="Exit code."),
    ],
    run=_run,
)
