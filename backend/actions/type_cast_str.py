from models import ActionDef, ActionInput, ActionOutput


def _run(inputs: dict, context: dict) -> dict:
    value = inputs["value"]
    result = str(value)
    return {"result": result}


ACTION = ActionDef(
    id="type_cast.str",
    category="Type Cast",
    name="Cast to String",
    description="Cast a value to a string.",
    icon="change_circle",
    color="purple",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(name="value", type="string", label="Value", required=True),
    ],
    outputs=[
        ActionOutput(name="result", type="string", label="Result"),
    ],
    run=_run,
)
