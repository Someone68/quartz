import 'package:flutter/material.dart' hide Step;
import 'package:flutter/services.dart';
import 'package:quartz/extensions.dart';
import 'package:quartz/modules/custom_tec.dart';
import 'package:quartz/modules/misc.dart';
import 'package:quartz/modules/option_picker.dart';
import 'package:quartz/types.dart';

/// Above this many options a 'choice' input uses the lazy [showOptionPicker]
/// sheet instead of [DropdownMenuFormField]. See the comment at its use site.
const _kMaxInlineChoices = 25;

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
              children: [
                Expanded(
                  child: Text(
                    def.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 96),
                  child: Text(
                    widget.step?.id ?? "",
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(128),
                    ),
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
                  if (_visibleInputs(def).isNotEmpty) ...[
                    ..._visibleInputs(
                      def,
                    ).map((input) => _buildField(context, input)),
                  ] else
                    Text(
                      'Step has no inputs.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
                                buildStyledTooltip(
                                  context: context,
                                  message:
                                      "${output.label}\n\n\"${output.name}\" is of type \"${output.type}\".\nYou can reference this output using {{steps.${widget.step!.id}.${output.name}}} (click to copy)",
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

  /// Inputs whose `requires` gate is currently satisfied. Hidden inputs keep
  /// their stored value, so flipping the gating field back restores what the
  /// user typed.
  List<ActionInput> _visibleInputs(ActionDef def) {
    final byName = {for (final i in def.inputs) i.name: i};
    final requires = {for (final i in def.inputs) i.name: i.requires};
    dynamic valueOf(String name) =>
        widget.step?.getField(name) ?? byName[name]?.default_;
    return def.inputs
        .where((i) => inputVisible(i.name, requires, valueOf))
        .toList();
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
        final options = input.options ?? const <String>[];
        final selected = options.contains(value) ? value as String : null;
        final mono = Theme.of(
          context,
        ).extension<AppTextThemes>()!.mono.bodyMedium;
        field = options.length > _kMaxInlineChoices
            // DropdownMenu is not lazy: it mounts every entry offstage to
            // measure the widest label, and the open menu panel is a plain
            // Column. A few hundred options (timezones) make every layout pass
            // walk all of them. Swap to a lazy searchable sheet instead.
            ? OutlinedButton(
                key: ValueKey(input.name),
                onPressed: () => showOptionPicker(
                  context,
                  options: options,
                  selected: selected,
                  hintText: 'Search ${input.label.toLowerCase()}',
                  onSelect: set,
                ),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selected ?? 'Choose ${input.label.toLowerCase()}',
                        style: mono,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              )
            : DropdownMenuFormField<String>(
                textStyle: mono,
                // enableFilter: true,
                enableSearch: true,
                // Takes the parent's width, which also skips the offstage
                // intrinsic-width measurement of every entry.
                expandedInsets: EdgeInsets.zero,
                initialSelection: selected,
                dropdownMenuEntries: options
                    .map((o) => DropdownMenuEntry(value: o, label: o))
                    .toList(),
                onSelected: set,
                menuHeight: 300,
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
      case 'datetime':
        field = TimePickerField(
          // Config stores an ISO-8601 string so the shortcut stays
          // JSON-encodable; a raw DateTime breaks jsonEncode on save.
          initial: value != null
              ? TimeOfDay.fromDateTime(DateTime.parse(value))
              : null,
          onChanged: (dt) => set(dt.toIso8601String()),
        );
        break;
      case 'app':
        field = Row(
          children: [
            Flexible(
              child: ActionChip(
                label: Text(
                  value != null ? truncate(value.toString(), 20) : 'Choose App',
                ),
                onPressed: () =>
                    showAppPicker(context, onSelect: (app) => set(app.name)),
              ),
            ),
            const SizedBox(width: 8),
            if (value != null)
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => set(null),
                iconSize: 16,
                padding: EdgeInsets.all(4),
                constraints: BoxConstraints(),
              ),
          ],
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
                InputLabelRow(
                  label: input.label,
                  required: input.required,
                  tooltip: input.tooltip,
                ),
                const SizedBox(height: 4),
                field,
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: InputLabelRow(
                    label: input.label,
                    required: input.required,
                    tooltip: input.tooltip,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 8),
                field,
              ],
            ),
    );
  }
}
