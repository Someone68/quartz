from models import ActionDef, ActionInput, ActionOutput


def _run(inputs: dict, context: dict) -> dict:
    value = inputs["value"]
    result = float(value)
    return {"result": result}


ACTION = ActionDef(
    id="type_cast.num",
    category="Type Cast",
    name="Cast to Number",
    description="Cast a value to a number.",
    icon="change_circle",
    color="cyan",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(name="value", type="string", label="Value", required=True),
    ],
    outputs=[
        ActionOutput(name="result", type="number", label="Result"),
    ],
    run=_run,
)
