import requests

from models import ActionDef, ActionInput, ActionOutput


def _run(inputs: dict, context: dict) -> dict:
    url = inputs["url"]
    method = inputs["method"]
    body = inputs.get("body")

    response = requests.request(method, url, data=body)
    return {"response": response.text}


ACTION = ActionDef(
    id="misc.send_web_request",
    category="Misc",
    name="Send Web Request",
    description="Send a web request to a specified URL",
    icon="schedule_send",
    color="orange",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(
            name="url",
            label="URL",
            type="string",
            tooltip="The URL to send the request to",
            required=True,
        ),
        ActionInput(
            name="method",
            label="Method",
            type="choice",
            tooltip="The HTTP method to use",
            required=True,
            options=["GET", "POST", "PUT", "DELETE"],
            default="GET",
        ),
        ActionInput(
            name="body",
            label="Body",
            type="string",
            tooltip="The body of the request",
            required=False,
            default="",
        ),
    ],
    outputs=[
        ActionOutput(
            name="response",
            label="The response from the web request",
            type="string",
        ),
    ],
    run=_run,
)
