import 'dart:convert';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter/services.dart';
import 'package:ui/color_map.dart';
import 'package:ui/hue_scheme.dart';
import 'package:ui/modules/action_libary.dart';
import 'package:ui/modules/misc.dart';
import 'package:ui/modules/resizable_container.dart';
import 'package:ui/modules/step_card.dart';
import 'package:ui/requests.dart';
import 'package:ui/types.dart';

/// Shortcut editor — trigger + step list. Placeholder until the builder UI
/// lands.

class EditorPage extends StatefulWidget {
  final Shortcut shortcut;

  const EditorPage({super.key, required this.shortcut});

  @override
  State<EditorPage> createState() => EditorPageState();
}

class EditorPageState extends State<EditorPage> {
  /// Full action definitions (with input/output schema) keyed by action id.
  /// The action-library picker only carries summaries, so we look up the
  /// schema here to seed steps and drive the inspector.
  late final Map<String, ActionDef> _actionDefs = {
    for (final def in getAllStepDefs()) def.id: def,
  };

  /// Index of the step currently shown in the inspector.
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final steps = widget.shortcut.steps;
    final selected = (_selectedIndex != null && _selectedIndex! < steps.length)
        ? steps[_selectedIndex!]
        : null;
    // Actions key by action id; control-flow steps key by their type ('if',
    // 'wait', ...), which matches the def id used in the palette.
    final selectedDef = selected == null
        ? null
        : selected is ActionStep
        ? _actionDefs[selected.actionId]
        : _actionDefs[selected.type];

    void _save(BuildContext context) {
      // Empty id = never persisted → create (POST). Otherwise update (PUT).
      final isNew = widget.shortcut.id.isEmpty;
      final request = isNew
          ? saveShortcut(widget.shortcut)
          : updateShortcut(widget.shortcut);
      request
          .then((saved) {
            // Adopt the server-minted id so subsequent saves update in place.
            setState(() => widget.shortcut.id = saved.id);
            print('saved successfully: ${saved.id}');
            showSnackBar(context, 'Saved successfully');
          })
          .catchError((e) {
            print('save failed: $e');
          });
    }

    void _editName() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit Shortcut Name'),
          content: TextField(
            controller: TextEditingController(text: widget.shortcut.name),
            onChanged: (value) => setState(() => widget.shortcut.name = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      // appBar: AppBar(title: const Text('Editor')),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Column(
                spacing: 16.0,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                    child: Column(
                      spacing: 16.0,
                      children: [
                        ...steps.asMap().entries.map(
                          (e) => GestureDetector(
                            onTap: () => setState(() => _selectedIndex = e.key),
                            child: StepCard(
                              label: e.value.label ?? "error",
                              icon:
                                  symbolFromName(e.value.icon) ??
                                  Icons.warning_rounded,
                              iconColor: context
                                  .hue(
                                    getColor(
                                      e.value.color ?? "cs-error",
                                      context,
                                    ),
                                  )
                                  .primaryContainer,
                              isSelected: _selectedIndex == e.key,
                              description: e.value.description,
                            ),
                          ),
                        ),
                        AddActionButton(
                          onActionSelected: (action) {
                            final def = _actionDefs[action.id];
                            if (def == null) return;
                            setState(() {
                              widget.shortcut.addStep(def: def);
                              _selectedIndex = widget.shortcut.steps.length - 1;
                            });
                          },
                        ),
                        FloatingActionButton.extended(
                          label: Text("debug: print shortcut"),
                          onPressed: () {
                            printObject(widget.shortcut);
                          },
                        ),
                      ],
                    ),
                  ),

                  Spacer(),
                  BottomAppBar(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      spacing: 16,
                      children: [
                        SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.shortcut.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                  textAlign: TextAlign.left,
                                ),
                                SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: _editName,
                                  iconSize: 16,
                                  padding: EdgeInsets.all(4),
                                  constraints: BoxConstraints(),
                                ),
                              ],
                            ),

                            Text(
                              widget.shortcut.id.isEmpty
                                  ? 'New Shortcut'
                                  : ' ${widget.shortcut.id}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(128),
                                  ),

                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                        Spacer(),
                        ElevatedButton(
                          child: const Text('Copy ID'),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: widget.shortcut.id),
                            );
                            showSnackBar(context, 'ID copied to clipboard');
                          },
                        ),
                        ElevatedButton(
                          onPressed: () => _save(context),
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              Theme.of(context).colorScheme.primaryContainer,
                            ),
                            foregroundColor: WidgetStateProperty.all(
                              Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          child: const Text('Save'),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              runShortcutWithLog(context, widget.shortcut.id),
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              Theme.of(context).colorScheme.secondaryContainer,
                            ),
                            foregroundColor: WidgetStateProperty.all(
                              Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                            ),
                          ),
                          child: const Text('Run'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: ResizableContainer(
                  resizeFromLeft: true,
                  initialWidth: 280,
                  minWidth: 250,
                  maxWidth: 600,
                  height: double.infinity,
                  handleWidth: 6,
                  handleColor: Theme.of(context).colorScheme.surfaceBright,
                  child: Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                    child: InspectorPanel(
                      // Rebuild inspector state when the selected step changes.
                      key: ValueKey(selected?.id),
                      def: selectedDef,
                      step: selected,
                      onDelete: selected == null
                          ? null
                          : () => setState(() {
                              widget.shortcut.steps.removeWhere(
                                (s) => s.id == selected.id,
                              );
                              _selectedIndex = null;
                            }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Full action definitions from the backend-written cache at
// ~/.config/quartz/actions_cache.json (includes input/output schema).
List<ActionDef> getActionDefs() {
  final home =
      Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      '~';
  final cachePath = '$home/.config/quartz/actions_cache.json';
  final actionsMap =
      jsonDecode(File(cachePath).readAsStringSync()) as Map<String, dynamic>;

  return actionsMap.entries
      .expand<ActionDef>(
        (entry) => (entry.value as List<dynamic>).map(
          (action) => ActionDef.fromJson(action as Map<String, dynamic>),
        ),
      )
      .toList();
}

// Control-flow / special steps. Modeled as ActionDefs so they flow through the
// same palette → seed → inspector pipeline as real actions. Their `id` doubles
// as the step `type`. Branch/body containers (if.then/else, loop/repeat body)
// are child step-id lists handled on the canvas, not scalar inputs here.
List<ActionDef> getControlFlowDefs() => [
  ActionDef(
    id: 'if',
    category: 'Control Flow',
    name: 'If / Else',
    description: 'Branch on a condition.',
    icon: 'arrow_split',
    color: 'cs-secondary',
    platforms: const ['linux', 'windows'],
    inputs: [
      ActionInput(
        name: 'condition',
        type: 'template',
        label: 'Condition',
        required: true,
      ),
    ],
    outputs: const [],
  ),
  ActionDef(
    id: 'loop',
    category: 'Control Flow',
    name: 'Loop',
    description: 'Iterate over a list, binding each item to a variable.',
    icon: 'cycle',
    color: 'cs-secondary',
    platforms: const ['linux', 'windows'],
    inputs: [
      ActionInput(
        name: 'over',
        type: 'template',
        label: 'List',
        required: true,
      ),
      ActionInput(
        name: 'variable',
        type: 'string',
        label: 'Item variable',
        required: true,
        default_: 'item',
      ),
    ],
    outputs: const [],
  ),
  ActionDef(
    id: 'repeat',
    category: 'Control Flow',
    name: 'Repeat',
    description: 'Run the body a fixed number of times.',
    icon: 'rotate_right',
    color: 'cs-secondary',
    platforms: const ['linux', 'windows'],
    inputs: [
      ActionInput(
        name: 'times',
        type: 'number',
        label: 'Times',
        required: true,
        default_: 1,
        min: 1,
      ),
    ],
    outputs: const [],
  ),
  ActionDef(
    id: 'set_var',
    category: 'Control Flow',
    name: 'Set Variable',
    description: 'Assign a value to a variable.',
    icon: 'data_object',
    color: 'cs-secondary',
    platforms: const ['linux', 'windows'],
    inputs: [
      ActionInput(
        name: 'var_name',
        type: 'string',
        label: 'Name',
        required: true,
      ),
      ActionInput(
        name: 'var_type',
        type: 'choice',
        label: 'Type',
        required: true,
        default_: 'string',
        options: const ['string', 'number', 'boolean', 'list', 'auto'],
      ),
      ActionInput(name: 'value', type: 'template', label: 'Value'),
    ],
    outputs: const [],
  ),
  ActionDef(
    id: 'wait',
    category: 'Control Flow',
    name: 'Wait',
    description: 'Pause before the next step.',
    icon: 'timer',
    color: 'cs-secondary',
    platforms: const ['linux', 'windows'],
    inputs: [
      ActionInput(
        name: 'duration',
        type: 'number',
        label: 'Duration (seconds)',
        required: true,
        default_: 1,
        min: 0,
      ),
    ],
    outputs: const [],
  ),
  ActionDef(
    id: 'stop',
    category: 'Control Flow',
    name: 'Stop',
    description: 'Halt the shortcut.',
    icon: 'stop_circle',
    color: 'cs-secondary',
    platforms: const ['linux', 'windows'],
    inputs: [ActionInput(name: 'message', type: 'string', label: 'Message')],
    outputs: const [],
  ),
];

// All palette entries: real actions plus control-flow steps.
List<ActionDef> getAllStepDefs() => [
  ...getActionDefs(),
  ...getControlFlowDefs(),
];

// Lightweight summaries for the action-library picker.
List<ActionSummary> getActionSummaries() => getAllStepDefs()
    .map(
      (d) => ActionSummary(
        id: d.id,
        name: d.name,
        description: d.description ?? '',
        icon: d.icon,
        color: d.color ?? 'cs-secondary',
        platforms: d.platforms,
        category: d.category,
      ),
    )
    .toList();

class AddActionButton extends StatelessWidget {
  final ValueChanged<ActionSummary>? onActionSelected;

  const AddActionButton({super.key, this.onActionSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // width: double.infinity,
      height: 60,
      child: GestureDetector(
        onTap: () async {
          final action = await showActionLibrary(context, getActionSummaries());
          if (action != null) onActionSelected?.call(action);
        },
        child: DottedBorder(
          color: Theme.of(context).colorScheme.surfaceBright,
          strokeWidth: 2,
          dashPattern: const [8, 4], // dash, gap
          borderType: BorderType.RRect,
          radius: const Radius.circular(8),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.all(0.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 24),
                      const SizedBox(width: 16),
                      Text(
                        "Add Action",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
        field = TextFormField(
          initialValue: value?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(isDense: true),
          onChanged: (v) => set(num.tryParse(v)),
          maxLines: null,
        );
        break;
      default: // string, path, template, and anything unknown
        field = TextFormField(
          initialValue: value?.toString() ?? '',
          decoration: const InputDecoration(isDense: true),
          onChanged: set,
          maxLines: null,
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
