from models import ActionDef, ActionInput, ActionOutput


def _run(inputs: dict, context: dict) -> dict:
    value = inputs["value"]
    result = bool(value)
    return {"result": result}


ACTION = ActionDef(
    id="type_cast.bool",
    category="Type Cast",
    name="Cast to Boolean",
    description="Cast a value to a boolean.",
    icon="change_circle",
    color="purple",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(name="value", type="string", label="Value", required=True),
    ],
    outputs=[
        ActionOutput(name="result", type="boolean", label="Result"),
    ],
    run=_run,
)
