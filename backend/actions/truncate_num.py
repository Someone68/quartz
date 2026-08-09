import math

from models import ActionDef, ActionInput, ActionOutput


def _run(inputs: dict, context: dict) -> dict:
    value = float(inputs["value"])
    raw_places = inputs.get("places")
    places = int(raw_places) if raw_places not in (None, "") else -1
    remove_zeros = bool(inputs["remove_zeros"])
    rounding = inputs["rounding"]
    if places != -1:
        factor = 10 ** places
        if rounding == "round":
            result = round(value, places)
        elif rounding == "floor":
            result = math.floor(value * factor) / factor
        else:  # ceil
            result = math.ceil(value * factor) / factor
    else:
        result = value

    result = float(result)
    if remove_zeros and result.is_integer():
        result = int(result)
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
            required=False,
            tooltip="The number of decimal places to truncate to.",
        ),
        ActionInput(
            name="remove_zeros",
            type="boolean",
            label="Remove Trailing Zeros",
            required=True,
            tooltip="Whether to remove trailing zeros from the result. (e.g. 1.00 becomes 1)",
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
