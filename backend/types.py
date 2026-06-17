from typing import Any, Literal

from pydantic.fields import Field
from pydantic.main import BaseModel
from typing_extensions import Callable


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
    platforms: list[str]
    inputs: list[ActionInput]
    outputs: list[ActionOutput]
    run: Callable = Field(exclude=True)

    model_config = {"arbitrary_types_allowed": True}
