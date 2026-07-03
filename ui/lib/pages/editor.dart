import 'dart:convert';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:ui/modules/action_libary.dart';
import 'package:ui/modules/misc.dart';
import 'package:ui/modules/resizable_container.dart';
import 'package:ui/modules/step_card.dart';
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

    return Scaffold(
      // appBar: AppBar(title: const Text('Editor')),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
              ),
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
                        iconColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        isSelected: _selectedIndex == e.key,
                      ),
                    ),
                  ),
                  AddActionButton(
                    onActionSelected: (action) {
                      final def = _actionDefs[action.id];
                      if (def == null) return;
                      widget.shortcut.addStep(def: def);
                      setState(
                        () => _selectedIndex = widget.shortcut.steps.length - 1,
                      );
                    },
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

// Full action definitions from tmp_actions_list.json (includes input/output
// schema).
List<ActionDef> getActionDefs() {
  final actionsMap =
      jsonDecode(File('lib/tmp_actions_list.json').readAsStringSync())
          as Map<String, dynamic>;

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
    platforms: const ['linux', 'windows'],
    inputs: [
      ActionInput(
        name: 'var_name',
        type: 'string',
        label: 'Name',
        required: true,
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
    platforms: const ['linux', 'windows'],
    inputs: [
      ActionInput(name: 'message', type: 'string', label: 'Message'),
    ],
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

  const InspectorPanel({super.key, this.def, this.step});

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
          Text('Inspector', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          if (def == null)
            Text(
              'Select a step to edit its inputs.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...def.inputs.map((input) => _buildField(context, input)),
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
        field = Switch(value: value == true, onChanged: set);
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
        );
        break;
      default: // string, path, template, and anything unknown
        field = TextFormField(
          initialValue: value?.toString() ?? '',
          decoration: const InputDecoration(isDense: true),
          onChanged: set,
        );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            input.required ? '${input.label} *' : input.label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          field,
        ],
      ),
    );
  }
}
