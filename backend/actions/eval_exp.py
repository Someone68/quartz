from models import ActionDef, ActionInput, ActionOutput
from simpleeval import simple_eval


def _run(inputs: dict, context: dict) -> dict:
    value = inputs["value"]
    result = simple_eval(value)
    return {"result": result}


ACTION = ActionDef(
    id="math.eval_exp",
    category="Math",
    name="Evaluate Expression",
    description="Evaluate a mathematical expression.",
    icon="calculate",
    color="colors.lime",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(name="value", type="string", label="Value", required=True),
    ],
    outputs=[
        ActionOutput(name="result", type="number", label="Result"),
    ],
    run=_run,
)
