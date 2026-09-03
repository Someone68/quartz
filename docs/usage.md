# Usage

If you haven't installed quartz yet, [install it first](installing.md).

## Running Quartz

On linux, make sure you have the quartzd service running. To enable it, run:

```bash
sudo systemctl --user enable --now quartzd
```

Then just run the quartz app through an app launcher or terminal.

## Shortcuts

Shortcuts are what you run, either through a trigger or manually. They consist of a series of steps that are executed in order.

## Steps/Actions

Actions are parts of a shortcut that define what to do. They are executed in order, and can have their own outputs. For example, a `Run Shell Command` action can return the output of the command, which can be used in subsequent actions.

Each step has its own ID, shown at the top of the inspector panel when selecting it (e.g. `s0`, `s1`, `s2`). These IDs are generated in the order the steps are added to the shortcut. They allow you to reference previous steps' outputs in subsequent actions.

You can find a list of outputs for every action in the `Outputs` section shown below.

![Outputs](https://github.com/Someone68/quartz/blob/main/outputs_screenshot.png?raw=true)

> [!NOTE]
> Like in programming, every variable, action output, and trigger output has a data type associated with it (e.g. `string`, `number`, `boolean`). Sometimes to do certain actions with them, you have to change its type (e.g. `{{variables.myVar}}` is a `string`, but you might want to use it as a `number`). To allow this, the Type Cast actions allow you to change the data type of an output. (e.g. Define variable, type cast to `number`, set variable as output of type cast action)
>
> Generally, it doesn't matter that much, since most actions automatically cast variables to the correct type when needed. However, the value of the variable should still match its intended type.

To use an output from an action, you can use the `{{steps.id.output}}` syntax in subsequent actions. For example, `{{steps.s0.stdout}}` would reference the `stdout` output of the first step. To make this easier, you can click on any output in the `Outputs` section to copy its code to the clipboard, and hover over it to see a description of it.

## Triggers

Triggers are what start your shortcuts. They can be configured to run on a schedule, or when a specific event occurs. They are very limited as of now, but still provide enough functionality.

Current triggers:

- On App Open
- On App Close
- On Clipboard Change
- On Directory Contents Change
- On Directory Modified
- On File Modified
- At a Specific Time (cron)
- On Startup

Some triggers have outputs, like On Clipboard Change, that can be used in subsequent actions. Their functionality is the same as outputs from actions, only the syntax is `{{trigger.output}}` (e.g. `{{trigger.value}}`).

## Variables and Scripting

> [!NOTE]
> Scripting actions can get quite complicated, so it's recommended that you have a basic understanding of programming before using them.

You can use variables and scripting in your shortcuts to make them more dynamic and powerful. Variables can store information temporarily to be used in your shortcut, and its value can be modified. To define a variable, simply use the Scripting: Set Variable action to set its type and value. To set the value of an existing variable, you can use the Scripting: Set Variable action again with the same variable name and type.

To reference a variable in an action, you can use the `{{variables.name}}` syntax. For example, `{{variables.myVar}}` would reference the `myVar` variable.

### If/Else Statements

If/Else statements allow you to conditionally execute actions based on the value of a variable, step output, or trigger output. Generally, the syntax is the same as in Python.

An example condition would be: `{{variables.myVar}} == 5`

> [!WARNING]
> When using variables in conditions, data type isn't carried over. This is especially important when dealing with strings.
>
> For example, if variable `myVar` is set to `hello`, `{{variables.myVar}} == "hello"` will **cause an error**, since the condition evalutes to `hello == "hello"`.
>
> The correct way to compare strings is to wrap your variable in quotes: `"{{variables.myVar}}" == "hello"` => `true`.

### Lists and Loops

You can define a variable as a list (seperate values with commas like this: `value1,value2,value3`) and use it in a loop action to iterate over its elements.

For example:

- Scripting: Set Variable: `myList` with type `list` and value `value1,value2,value3`
- Scripting: Loop: `{{variables.myList}}`, item variable: `item`
  - Output: Message Box: `{{variables.item}}`

...will show 3 message boxes in order: `value1`, `value2`, `value3`.

Each item is treated as a `string` type.

## Example

See the [example shortcut](example.md) for a step-by-step guide on creating your first shortcut.
