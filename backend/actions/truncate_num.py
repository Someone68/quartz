from models import ActionDef, ActionInput, ActionOutput


def _run(inputs: dict, context: dict) -> dict:
    value = int(inputs["value"])
    places = int(inputs["places"])
    rounding = inputs["rounding"]
    result = (
        round(value, places)
        if rounding == "round"
        else int(value)
        if rounding == "floor"
        else int(value) + 1
    )
    return {"result": result}


ACTION = ActionDef(
    id="math.truncate_num",
    category="Math",
    name="Truncate Number",
    description="Truncate a number to a specified number of decimal places.",
    icon="decimal_decrease",
    color="lime",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(
            name="value",
            type="number",
            label="Value",
            required=True,
            tooltip="The number to truncate.",
        ),
        ActionInput(
            name="places",
            type="number",
            label="Places",
            required=True,
            tooltip="The number of decimal places to truncate to.",
        ),
        ActionInput(
            name="rounding",
            type="choice",
            label="Rounding",
            required=True,
            tooltip="The rounding mode to use.",
            options=["round", "floor", "ceil"],
            default="floor",
        ),
    ],
    outputs=[
        ActionOutput(name="result", type="number", label="Result"),
    ],
    run=_run,
)
