from datetime import datetime
from typing import Annotated, Any, Callable, Literal
from uuid import uuid4

from pydantic import BaseModel, Field


class ActionInput(BaseModel):
    name: str
    type: Literal["string", "number", "boolean", "path", "choice", "template"]
    label: str
    required: bool = False
    default: Any = None
    options: list[str] | None = None
    min: float | None = None
    max: float | None = None


class ActionOutput(BaseModel):
    name: str
    type: Literal["string", "number", "boolean", "path", "list"]
    label: str


class ActionDef(BaseModel):
    id: str
    category: str
    name: str
    description: str | None = None
    icon: str
    color: str | None = None
    platforms: list[str]
    inputs: list[ActionInput]
    outputs: list[ActionOutput]
    run: Callable = Field(exclude=True)

    model_config = {"arbitrary_types_allowed": True}


class StepBase(BaseModel):
    id: str
    type: str
    label: str | None = None
    enabled: bool = True
    icon: str | None = None
    color: str | None = None

    model_config = {"arbitrary_types_allowed": True}


class ActionStep(StepBase):
    type: Literal["action"] = "action"
    action_id: str
    inputs: dict[str, Any] = {}


class SetVarStep(StepBase):
    type: Literal["set_var"] = "set_var"
    var_name: str
    value: Any


class RunShortcutStep(StepBase):
    type: Literal["run_shortcut"] = "run_shortcut"
    shortcut_id: str
    inputs: dict[str, Any] = {}
    wait: bool = True


class IfStep(StepBase):
    type: Literal["if"] = "if"
    condition: str
    then: list[str] = []
    else_: list[str] = Field(default=[], alias="else")

    model_config = {"populate_by_name": True}


class LoopStep(StepBase):
    type: Literal["loop"] = "loop"
    over: str
    variable: str
    steps: list[str] = []


class RepeatStep(StepBase):
    type: Literal["repeat"] = "repeat"
    times: int
    steps: list[str] = []


class WaitStep(StepBase):
    type: Literal["wait"] = "wait"
    duration: int


class StopStep(StepBase):
    type: Literal["stop"] = "stop"
    message: str | None = None


Step = Annotated[
    ActionStep
    | SetVarStep
    | IfStep
    | LoopStep
    | RepeatStep
    | WaitStep
    | StopStep
    | RunShortcutStep,
    Field(discriminator="type"),
]


class Trigger(BaseModel):
    type: str
    config: dict[str, Any] = {}


def new_id() -> str:
    return str(uuid4())


class Shortcut(BaseModel):
    id: str = Field(default_factory=new_id)
    name: str
    description: str = ""
    icon: str = "star"
    enabled: bool = True
    trigger: Trigger
    steps: list[Step] = []
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)

    model_config = {"arbitrary_types_allowed": True}

    def steps_by_id(self) -> dict[str, Step]:
        return {step.id: step for step in self.steps}


class RunLog(BaseModel):
    id: str = Field(default_factory=new_id)
    shortcut_id: str
    started_at: datetime = Field(default_factory=datetime.now)
    finished_at: datetime | None = None
    status: Literal["success", "failed", "stopped", "running"]
    error: str | None = None
    step_outputs: dict[str, Any] = {}


class ShortcutSummary(BaseModel):
    id: str
    name: str
    icon: str | None
    step_count: int
