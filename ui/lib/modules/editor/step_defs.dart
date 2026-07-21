import 'dart:convert';
import 'dart:io';

import 'package:ui/types.dart';

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
    category: 'Scripting',
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
    category: 'Scripting',
    name: 'Loop',
    description: 'Iterate over a list, binding each item to a variable.',
    icon: 'rotate_right',
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
    category: 'Scripting',
    name: 'Repeat',
    description: 'Run the body a fixed number of times.',
    icon: 'cycle',
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
    category: 'Scripting',
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
    category: 'Scripting',
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
    category: 'Scripting',
    name: 'Stop',
    description: 'Halt the shortcut.',
    icon: 'stop_circle',
    color: 'cs-secondary',
    platforms: const ['linux', 'windows'],
    inputs: [
      ActionInput(name: 'message', type: 'string', label: 'Message'),
      ActionInput(
        name: 'throwError',
        type: 'boolean',
        label: 'Throw Error',
        default_: false,
      ),
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
        color: d.color ?? 'cs-secondary',
        platforms: d.platforms,
        category: d.category,
      ),
    )
    .toList();
