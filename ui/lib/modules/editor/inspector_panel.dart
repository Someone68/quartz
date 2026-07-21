import 'package:flutter/material.dart' hide Step;
import 'package:flutter/services.dart';
import 'package:ui/extensions.dart';
import 'package:ui/modules/custom_tec.dart';
import 'package:ui/modules/misc.dart';
import 'package:ui/types.dart';

class InspectorPanel extends StatefulWidget {
  /// Schema for the selected step's action (null when nothing selected or the
  /// step is not an action step).
  final ActionDef? def;

  /// The selected step. Edits are written back through `setField`, which routes
  /// to the generic `inputs` map (actions) or typed config fields (control
  /// flow).
  final Step? step;

  /// Called when the Delete button is pressed. The parent owns the step list
  /// and its rebuild, so removal happens there.
  final VoidCallback? onDelete;

  const InspectorPanel({super.key, this.def, this.onDelete, this.step});

  @override
  State<InspectorPanel> createState() => InspectorPanelState();
}

class InspectorPanelState extends State<InspectorPanel> {
  @override
  Widget build(BuildContext context) {
    final def = widget.def;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (def != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(def.name, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  widget.step?.id ?? "",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(128),
                  ),
                ),
              ],
            ),
          ] else
            Text("Inspector", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          if (def == null)
            Text(
              'Select a step to edit its properties.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else ...[
            Expanded(
              child: ListView(
                children: [
                  ...def.inputs.map((input) => _buildField(context, input)),
                ],
              ),
            ),
            Column(
              children: [
                Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: widget.onDelete,
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.all(16.0),
                    width: double.infinity,
                    child: Column(
                      spacing: 8.0,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.def?.outputs.isNotEmpty ?? false) ...[
                          Text(
                            "Outputs",
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.left,
                          ),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: [
                              for (var output in widget.def!.outputs) ...[
                                Tooltip(
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  textStyle: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  message:
                                      "\"${output.name}\" is of type \"${output.type}\".\nYou can reference this output using {{steps.${widget.step!.id}.${output.name}}} (click to copy)",
                                  child: TinyChipButton(
                                    label: output.name,
                                    color: output.type == "string"
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer
                                        : output.type == "number"
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.secondaryContainer
                                        : output.type == "boolean"
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.tertiaryContainer
                                        : Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainer,
                                    context: context,
                                    onTap: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text:
                                              "{{steps.${widget.step!.id}.${output.name}}}",
                                        ),
                                      );
                                      showSnackBar(
                                        context,
                                        "Copied to clipboard",
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ] else
                          Text(
                            "No outputs",
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.left,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildField(BuildContext context, ActionInput input) {
    final step = widget.step;
    final value = step?.getField(input.name) ?? input.default_;
    void set(dynamic v) => setState(() => step?.setField(input.name, v));

    Widget field;
    switch (input.type) {
      case 'boolean':
        field = Checkbox(value: value == true, onChanged: set);
        break;
      case 'choice':
        field = DropdownButton<String>(
          style: Theme.of(context).extension<AppTextThemes>()!.mono.bodyMedium,
          isExpanded: true,
          value: (input.options?.contains(value) ?? false)
              ? value as String
              : null,
          items: (input.options ?? [])
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: set,
        );
        break;
      case 'number':
        field = CustomTextField(
          key: ValueKey(input.name),
          value: value?.toString() ?? '',
          decoration: const InputDecoration(isDense: true),
          // onChanged: (v) => set(num.tryParse(v)),
          onChanged: set,
        );
        break;
      default: // string, path, template, and anything unknown
        field = CustomTextField(
          key: ValueKey(input.name),
          value: value?.toString() ?? '',
          onChanged: set,
          decoration: const InputDecoration(isDense: true),
        );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: input.type != 'boolean'
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      input.label,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      input.required ? ' *' : '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                field,
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      input.label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      input.required ? ' *' : '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                field,
              ],
            ),
    );
  }
}
