//ported by claude
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

String newId() => const Uuid().v4();

class ActionInput {
  final String name;
  final String type; // string, number, boolean, path, choice, template
  final String label;
  final bool required;
  final dynamic default_;
  final List<String>? options;
  final double? min;
  final double? max;

  ActionInput({
    required this.name,
    required this.type,
    required this.label,
    this.required = false,
    this.default_,
    this.options,
    this.min,
    this.max,
  });

  factory ActionInput.fromJson(Map<String, dynamic> j) => ActionInput(
    name: j['name'],
    type: j['type'],
    label: j['label'],
    required: j['required'] ?? false,
    default_: j['default'],
    options: (j['options'] as List?)?.cast<String>(),
    min: (j['min'] as num?)?.toDouble(),
    max: (j['max'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'label': label,
    'required': required,
    'default': default_,
    'options': options,
    'min': min,
    'max': max,
  };
}

class ActionOutput {
  final String name;
  final String type; // string, number, boolean, path, list
  final String label;

  ActionOutput({required this.name, required this.type, required this.label});

  factory ActionOutput.fromJson(Map<String, dynamic> j) =>
      ActionOutput(name: j['name'], type: j['type'], label: j['label']);

  Map<String, dynamic> toJson() => {'name': name, 'type': type, 'label': label};
}

// Note: no `run` field here (excluded on the Python side too).
// Handle actual execution logic separately in Dart.
class ActionDef {
  final String id;
  final String category;
  final String name;
  final String? description;
  final String icon;
  final List<String> platforms;
  final List<ActionInput> inputs;
  final List<ActionOutput> outputs;

  ActionDef({
    required this.id,
    required this.category,
    required this.name,
    this.description,
    required this.icon,
    required this.platforms,
    required this.inputs,
    required this.outputs,
  });

  factory ActionDef.fromJson(Map<String, dynamic> j) => ActionDef(
    id: j['id'],
    category: j['category'],
    name: j['name'],
    description: j['description'],
    icon: j['icon'],
    platforms: (j['platforms'] as List).cast<String>(),
    inputs: (j['inputs'] as List).map((e) => ActionInput.fromJson(e)).toList(),
    outputs: (j['outputs'] as List)
        .map((e) => ActionOutput.fromJson(e))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'name': name,
    'description': description,
    'icon': icon,
    'platforms': platforms,
    'inputs': inputs.map((e) => e.toJson()).toList(),
    'outputs': outputs.map((e) => e.toJson()).toList(),
  };
}

// ---- Steps ----
// Sealed class mirrors the discriminated union on `type`.

sealed class Step {
  final String id;
  final String type;
  final String? label;
  final bool enabled;
  final String? icon;

  Step({
    required this.id,
    required this.type,
    this.label,
    this.enabled = true,
    this.icon,
  });

  Map<String, dynamic> toJson();

  static Step fromJson(Map<String, dynamic> j) {
    switch (j['type']) {
      case 'action':
        return ActionStep.fromJson(j);
      case 'set_var':
        return SetVarStep.fromJson(j);
      case 'run_shortcut':
        return RunShortcutStep.fromJson(j);
      case 'if':
        return IfStep.fromJson(j);
      case 'loop':
        return LoopStep.fromJson(j);
      case 'repeat':
        return RepeatStep.fromJson(j);
      case 'wait':
        return WaitStep.fromJson(j);
      case 'stop':
        return StopStep.fromJson(j);
      default:
        throw ArgumentError('Unknown step type: ${j['type']}');
    }
  }
}

class ActionStep extends Step {
  final String actionId;
  final Map<String, dynamic> inputs;

  ActionStep({
    required super.id,
    required super.icon,
    super.label,
    super.enabled,
    required this.actionId,
    this.inputs = const {},
  }) : super(type: 'action');

  factory ActionStep.fromJson(Map<String, dynamic> j) => ActionStep(
    id: j['id'],
    label: j['label'],
    enabled: j['enabled'] ?? true,
    actionId: j['action_id'],
    inputs: (j['inputs'] as Map?)?.cast<String, dynamic>() ?? {},
    icon: j['icon'],
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'label': label,
    'enabled': enabled,
    'action_id': actionId,
    'inputs': inputs,
    'icon': icon,
  };
}

class SetVarStep extends Step {
  final String varName;
  final dynamic value;

  SetVarStep({
    required super.id,
    super.label,
    super.enabled,
    required this.varName,
    this.value,
  }) : super(type: 'set_var');

  factory SetVarStep.fromJson(Map<String, dynamic> j) => SetVarStep(
    id: j['id'],
    label: j['label'],
    enabled: j['enabled'] ?? true,
    varName: j['var_name'],
    value: j['value'],
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'label': label,
    'enabled': enabled,
    'var_name': varName,
    'value': value,
  };
}

class RunShortcutStep extends Step {
  final String shortcutId;
  final Map<String, dynamic> inputs;
  final bool wait;

  RunShortcutStep({
    required super.id,
    super.label,
    super.enabled,
    required this.shortcutId,
    this.inputs = const {},
    this.wait = true,
  }) : super(type: 'run_shortcut');

  factory RunShortcutStep.fromJson(Map<String, dynamic> j) => RunShortcutStep(
    id: j['id'],
    label: j['label'],
    enabled: j['enabled'] ?? true,
    shortcutId: j['shortcut_id'],
    inputs: (j['inputs'] as Map?)?.cast<String, dynamic>() ?? {},
    wait: j['wait'] ?? true,
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'label': label,
    'enabled': enabled,
    'shortcut_id': shortcutId,
    'inputs': inputs,
    'wait': wait,
  };
}

class IfStep extends Step {
  final String condition;
  final List<String> then;
  final List<String> else_;

  IfStep({
    required super.id,
    required super.icon,
    super.label,
    super.enabled,
    required this.condition,
    this.then = const [],
    this.else_ = const [],
  }) : super(type: 'if');

  factory IfStep.fromJson(Map<String, dynamic> j) => IfStep(
    id: j['id'],
    icon: "arrow_split",
    label: j['label'],
    enabled: j['enabled'] ?? true,
    condition: j['condition'],
    then: (j['then'] as List?)?.cast<String>() ?? [],
    else_: (j['else'] as List?)?.cast<String>() ?? [],
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'label': label,
    'enabled': enabled,
    'condition': condition,
    'then': then,
    'else': else_,
  };
}

class LoopStep extends Step {
  final String over;
  final String variable;
  final List<String> steps;

  LoopStep({
    required super.id,
    required super.icon,
    super.label,
    super.enabled,
    required this.over,
    required this.variable,
    this.steps = const [],
  }) : super(type: 'loop');

  factory LoopStep.fromJson(Map<String, dynamic> j) => LoopStep(
    id: j['id'],
    icon: "cycle",
    label: j['label'],
    enabled: j['enabled'] ?? true,
    over: j['over'],
    variable: j['variable'],
    steps: (j['steps'] as List?)?.cast<String>() ?? [],
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'label': label,
    'enabled': enabled,
    'over': over,
    'variable': variable,
    'steps': steps,
  };
}

class RepeatStep extends Step {
  final int times;
  final List<String> steps;

  RepeatStep({
    required super.id,
    required super.icon,
    super.label,
    super.enabled,
    required this.times,
    this.steps = const [],
  }) : super(type: 'repeat');

  factory RepeatStep.fromJson(Map<String, dynamic> j) => RepeatStep(
    id: j['id'],
    icon: "rotate_right",
    label: j['label'],
    enabled: j['enabled'] ?? true,
    times: j['times'],
    steps: (j['steps'] as List?)?.cast<String>() ?? [],
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'label': label,
    'enabled': enabled,
    'times': times,
    'steps': steps,
  };
}

class WaitStep extends Step {
  final int duration;

  WaitStep({
    required super.id,
    required super.icon,
    super.label,
    super.enabled,
    required this.duration,
  }) : super(type: 'wait');

  factory WaitStep.fromJson(Map<String, dynamic> j) => WaitStep(
    id: j['id'],
    icon: "timer",
    label: j['label'],
    enabled: j['enabled'] ?? true,
    duration: j['duration'],
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'label': label,
    'enabled': enabled,
    'duration': duration,
  };
}

class StopStep extends Step {
  final String? message;

  StopStep({
    required super.id,
    required super.icon,
    super.label,
    super.enabled,
    this.message,
  }) : super(type: 'stop');

  factory StopStep.fromJson(Map<String, dynamic> j) => StopStep(
    id: j['id'],
    icon: "stop_circle",
    label: j['label'],
    enabled: j['enabled'] ?? true,
    message: j['message'],
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'label': label,
    'enabled': enabled,
    'message': message,
  };
}

// ---- Trigger ----

class Trigger {
  final String type;
  final Map<String, dynamic> config;

  Trigger({required this.type, this.config = const {}});

  factory Trigger.fromJson(Map<String, dynamic> j) => Trigger(
    type: j['type'],
    config: (j['config'] as Map?)?.cast<String, dynamic>() ?? {},
  );

  Map<String, dynamic> toJson() => {'type': type, 'config': config};
}

// ---- Shortcut ----

class Shortcut {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool enabled;
  final Trigger trigger;
  final List<Step> steps;
  final DateTime createdAt;
  final DateTime updatedAt;

  Shortcut({
    String? id,
    required this.name,
    this.description = '',
    this.icon = 'star',
    this.enabled = true,
    required this.trigger,
    this.steps = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? newId(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, Step> stepsById() => {for (final s in steps) s.id: s};

  void addActionStep({required ActionSummary action}) {
    steps.add(
      ActionStep(
        actionId: action.id,
        id: "s${steps.length}",
        enabled: true,
        inputs: {},
        label: action.name,
        icon: action.icon,
      ),
    );
  }

  factory Shortcut.fromJson(Map<String, dynamic> j) => Shortcut(
    id: j['id'],
    name: j['name'],
    description: j['description'] ?? '',
    icon: j['icon'] ?? 'star',
    enabled: j['enabled'] ?? true,
    trigger: Trigger.fromJson(j['trigger']),
    steps: (j['steps'] as List? ?? []).map((e) => Step.fromJson(e)).toList(),
    createdAt: DateTime.parse(j['created_at']),
    updatedAt: DateTime.parse(j['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon': icon,
    'enabled': enabled,
    'trigger': trigger.toJson(),
    'steps': steps.map((e) => e.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

// ---- RunLog ----

class RunLog {
  final String id;
  final String shortcutId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String status; // success, failed, stopped, running
  final String? error;
  final Map<String, dynamic> stepOutputs;

  RunLog({
    String? id,
    required this.shortcutId,
    DateTime? startedAt,
    this.finishedAt,
    required this.status,
    this.error,
    this.stepOutputs = const {},
  }) : id = id ?? newId(),
       startedAt = startedAt ?? DateTime.now();

  factory RunLog.fromJson(Map<String, dynamic> j) => RunLog(
    id: j['id'],
    shortcutId: j['shortcut_id'],
    startedAt: DateTime.parse(j['started_at']),
    finishedAt: j['finished_at'] != null
        ? DateTime.parse(j['finished_at'])
        : null,
    status: j['status'],
    error: j['error'],
    stepOutputs: (j['step_outputs'] as Map?)?.cast<String, dynamic>() ?? {},
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'shortcut_id': shortcutId,
    'started_at': startedAt.toIso8601String(),
    'finished_at': finishedAt?.toIso8601String(),
    'status': status,
    'error': error,
    'step_outputs': stepOutputs,
  };
}

// ---- ShortcutSummary ----

class ShortcutSummary {
  final String id;
  final String name;
  final String? icon;
  final int stepCount;

  ShortcutSummary({
    required this.id,
    required this.name,
    this.icon,
    required this.stepCount,
  });

  factory ShortcutSummary.fromJson(Map<String, dynamic> j) => ShortcutSummary(
    id: j['id'],
    name: j['name'],
    icon: j['icon'],
    stepCount: j['step_count'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'step_count': stepCount,
  };
}

// action summary
class ActionSummary {
  final String id;
  final String name;
  final String category;
  final String description;
  final String icon;
  final List<String> platforms;

  ActionSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.icon,
    required this.platforms,
  });
}
