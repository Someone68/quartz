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

## Create your first shortcut

Try creating your first shortcut by going to the editor, or pressing the "Create Shortcut" button on the dashboard. This will open an empty shortcut editor.

### Example shortcut: Add 2 numbers

1. Press "Add Action" to open a list of available actions. Let's first ask for some input from the user. Add a "Input: Dialog Box" action.
2. On the right, you will see an inspector with fields to configure the dialog box. Set the title and prompt (e.g. "First number:"). Make sure the backend is set correctly (see tooltip for more info.)
3. Now let's add the second input. Press "Add Action" again and add another "Input: Dialog Box" action. Set the title and prompt (e.g. "Second number:"). Make sure the backend is set correctly (see tooltip for more info.)
4. Click on the first dialog box action. On the bottom right of the inspector is a list of step outputs. You can reference these outputs in future steps (e.g. "{{steps.id.output1}}"). Click on the `response` output to copy its code to the clipboard.
5. If you look closely, the `response` output is of type `string`. If you are new to programming, strings are another way to say "text". To do math with these strings, you need to convert them to numbers first.
6. To convert a string to a number, you will need to use the "Type Cast: Cast to Number" action. Add this action to your shortcut and set the `value` field to the `response` output of the first dialog box action. (If you copied the `response` output to the clipboard earlier, you can paste it here.)
7. Now let's add the second "Type Cast: Cast to Number" action. Set the `value` field to the `response` output of the second dialog box action. (You can copy the `response` output from the second dialog box action and paste it here.)
8. Now we have both responses converted to numbers, and we can use them in math operations. Add the "Math: Evaluate Expression" action to your shortcut and set the `value` field to the sum of the two converted numbers. To do this, copy the `result` output from the first "Math: Evaluate Expression" action and paste it here. Then add the `+` operator and the `result` output from the second "Math: Evaluate Expression" action to get the final sum. (`value` field should look something like: `{{s2.result}} + {{s3.result}}`)
9. With the final sum, we can show the result to the user using the "Output: Message Box" action. Set the `body` field to the `value` output of the "Math: Evaluate Expression" action. (`body` field should look something like: `{{s4.result}}`) Make sure to set the `title` field to a descriptive message so the user knows what the result is.

Congratulations! You have successfully created a shortcut that uses quartz to evaluate a mathematical expression and display the result to the user. Make sure to save your shortcut and test it out to make sure it works as expected.
