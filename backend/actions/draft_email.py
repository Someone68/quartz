import sys
import os
import shutil
import subprocess
import webbrowser
from urllib.parse import quote
from models import ActionDef, ActionInput, ActionOutput


def build_mailto(to=None, cc=None, bcc=None, subject='', body=''):
    to, cc, bcc = to or [], cc or [], bcc or []
    params = []
    if cc:
        params.append(('cc', ','.join(cc)))
    if bcc:
        params.append(('bcc', ','.join(bcc)))
    if subject:
        params.append(('subject', subject))
    if body:
        params.append(('body', body))
    query = '&'.join(f"{k}={quote(v)}" for k, v in params)
    return f"mailto:{','.join(to)}" + (f"?{query}" if query else "")


def _run(inputs: dict, context: dict) -> dict:
    def parse(key):
        return [x.strip() for x in str(inputs.get(key, "")).split(",") if x.strip()]

    to, cc, bcc = parse("to"), parse("cc"), parse("bcc")
    subject = inputs.get("subject") or ""
    body = inputs.get("body") or ""

    mailto = build_mailto(to, cc, bcc, subject, body)

    if sys.platform.startswith("win"):
        import os
        os.startfile(mailto)
        return {"mailto": mailto}

    if not shutil.which("xdg-open"):
        raise RuntimeError("xdg-open not found")

    rc = subprocess.run(
        ["xdg-open", mailto],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    ).returncode
    if rc == 0:
        return {"mailto": mailto}
    else:
        raise RuntimeError("Failed to open mailto: You probably don't have a default mail client set up.")



ACTION = ActionDef(
    id="misc.draft_email",
    category="Misc",
    name="Draft Email",
    description="Draft an email using the mailto protocol",
    icon="drafts",
    color="orange",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(
            name="to",
            label="To",
            tooltip="A list of recipients, separated by commas, like this: john@example.com, jane@example.com",
            type="string",
            required=True,
        ),
        ActionInput(
            name="cc",
            label="CC",
            tooltip="A list of CC recipients, separated by commas, like this: john@example.com, jane@example.com",
            type="string",
            required=False,
        ),
        ActionInput(
            name="bcc",
            label="BCC",
            tooltip="A list of BCC recipients, separated by commas, like this: john@example.com, jane@example.com",
            type="string",
            required=False,
        ),
        ActionInput(
            name="subject",
            label="Subject",
            type="string",
            required=False,
        ),
        ActionInput(
            name="body",
            label="Body",
            type="string",
            required=False,
        ),
        ActionInput(
            name="open_link",
            label="Open Link",
            type="boolean",
            default=True,
            tooltip="Whether to open the mail link in the default mail client",
            required=False,
        ),
    ],
    outputs=[
        ActionOutput(
            name="mailto",
            type="string",
            label="The mailto link generated from the input values",
        ),
    ],
    run=_run,
)
