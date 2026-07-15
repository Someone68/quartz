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
  final String? color;
  final List<String> platforms;
  final List<ActionInput> inputs;
  final List<ActionOutput> outputs;

  ActionDef({
    required this.id,
    required this.category,
    required this.name,
    this.description,
    required this.icon,
    this.color,
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
    color: j['color'],
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
    'color': color,
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
  final String? color;
  final Map<String, dynamic> inputs;

  Step({
    required this.id,
    required this.type,
    this.inputs = const {},
    this.label,
    this.enabled = true,
    this.icon,
    this.color,
  });

  Map<String, dynamic> toJson();

  // Optional human-readable description. Base steps have none; typed steps
  // that carry one (e.g. ActionStep) override this.
  String? get description => null;

  List<String>? get outputs => null;

  // Schema-driven config access for the inspector. Default backs onto the
  // generic `inputs` map (ActionStep). Typed steps (if/loop/...) override to
  // route named schema fields to/from their typed config fields.
  dynamic getField(String name) => inputs[name];
  void setField(String name, dynamic value) => inputs[name] = value;

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
  @override
  final String? description;

  ActionStep({
    required super.id,
    required super.icon,
    super.color,
    required super.inputs,
    super.label,
    super.enabled,
    required this.actionId,
    this.description,
  }) : super(type: 'action');

  factory ActionStep.fromJson(Map<String, dynamic> j) => ActionStep(
    id: j['id'],
    label: j['label'],
    enabled: j['enabled'] ?? true,
    actionId: j['action_id'],
    inputs: (j['inputs'] as Map?)?.cast<String, dynamic>() ?? {},
    icon: j['icon'],
    color: j['color'],
    description: j['description'],
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
    'color': color,
    'description': description,
  };
}

class SetVarStep extends Step {
  String varName;
  dynamic value;
  String varType;

  SetVarStep({
    required super.id,
    super.icon,
    super.color,
    super.label,
    super.enabled,
    required this.varName,
    this.value,
    this.varType = 'string',
  }) : super(type: 'set_var');

  factory SetVarStep.fromJson(Map<String, dynamic> j) => SetVarStep(
    id: j['id'],
    icon: j['icon'] ?? 'data_object',
    color: j['color'],
    label: j['label'],
    enabled: j['enabled'] ?? true,
    varName: j['var_name'],
    value: j['value'],
    varType: j['var_type'] ?? 'string',
  );

  @override
  dynamic getField(String name) => switch (name) {
    'var_name' => varName,
    'value' => value,
    'var_type' => varType,
    _ => super.getField(name),
  };

  @override
  void setField(String name, dynamic v) {
    switch (name) {
      case 'var_name':
        varName = v?.toString() ?? '';
      case 'value':
        value = v;
      case 'var_type':
        varType = v?.toString() ?? 'string';
      default:
        super.setField(name, v);
    }
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'label': label,
    'enabled': enabled,
    'var_name': varName,
    'value': value,
    'var_type': varType,
    'icon': icon,
    'color': color,
  };
}

class RunShortcutStep extends Step {
  final String shortcutId;
  final Map<String, dynamic> inputs;
  final bool wait;

  RunShortcutStep({
    required super.id,
    super.icon,
    super.color,
    super.label,
    super.enabled,
    required this.shortcutId,
    this.inputs = const {},
    this.wait = true,
  }) : super(type: 'run_shortcut');

  factory RunShortcutStep.fromJson(Map<String, dynamic> j) => RunShortcutStep(
    id: j['id'],
    icon: j['icon'],
    color: j['color'],
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
    'icon': icon,
    'color': color,
  };
}

class IfStep extends Step {
  String condition;
  final List<String> then;
  final List<String> else_;

  IfStep({
    required super.id,
    required super.icon,
    super.color,
    super.label,
    super.enabled,
    required this.condition,
    List<String>? then,
    List<String>? else_,
  }) : then = List.of(then ?? const []),
       else_ = List.of(else_ ?? const []),
       super(type: 'if');

  factory IfStep.fromJson(Map<String, dynamic> j) => IfStep(
    id: j['id'],
    icon: "arrow_split",
    color: j['color'],
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
    'color': color,
  };

  @override
  dynamic getField(String name) =>
      name == 'condition' ? condition : super.getField(name);

  @override
  void setField(String name, dynamic v) {
    if (name == 'condition') {
      condition = v?.toString() ?? '';
    } else {
      super.setField(name, v);
    }
  }
}

class LoopStep extends Step {
  String over;
  String variable;
  List<String> steps;

  LoopStep({
    required super.id,
    required super.icon,
    super.color,
    super.label,
    super.enabled,
    required this.over,
    required this.variable,
    List<String>? steps,
  }) : steps = List.of(steps ?? const []),
       super(type: 'loop');

  factory LoopStep.fromJson(Map<String, dynamic> j) => LoopStep(
    id: j['id'],
    icon: "cycle",
    color: j['color'],
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
    'color': color,
  };

  @override
  dynamic getField(String name) => switch (name) {
    'over' => over,
    'variable' => variable,
    _ => super.getField(name),
  };

  @override
  void setField(String name, dynamic v) {
    switch (name) {
      case 'over':
        over = v?.toString() ?? '';
      case 'variable':
        variable = v?.toString() ?? '';
      default:
        super.setField(name, v);
    }
  }
}

class RepeatStep extends Step {
  int times;
  List<String> steps;

  RepeatStep({
    required super.id,
    required super.icon,
    super.color,
    super.label,
    super.enabled,
    required this.times,
    List<String>? steps,
  }) : steps = List.of(steps ?? const []),
       super(type: 'repeat');

  factory RepeatStep.fromJson(Map<String, dynamic> j) => RepeatStep(
    id: j['id'],
    icon: "rotate_right",
    color: j['color'],
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
    'color': color,
  };

  @override
  dynamic getField(String name) =>
      name == 'times' ? times : super.getField(name);

  @override
  void setField(String name, dynamic v) {
    if (name == 'times') {
      times = (v as num?)?.toInt() ?? 0;
    } else {
      super.setField(name, v);
    }
  }
}

class WaitStep extends Step {
  int duration;

  WaitStep({
    required super.id,
    required super.icon,
    super.color,
    super.label,
    super.enabled,
    required this.duration,
  }) : super(type: 'wait');

  factory WaitStep.fromJson(Map<String, dynamic> j) => WaitStep(
    id: j['id'],
    icon: "timer",
    color: j['color'],
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
    'color': color,
  };

  @override
  dynamic getField(String name) =>
      name == 'duration' ? duration : super.getField(name);

  @override
  void setField(String name, dynamic v) {
    if (name == 'duration') {
      duration = (v as num?)?.toInt() ?? 0;
    } else {
      super.setField(name, v);
    }
  }
}

class StopStep extends Step {
  String? message;
  bool throwError;

  StopStep({
    required super.id,
    required super.icon,
    super.color,
    super.label,
    super.enabled,
    this.message,
    this.throwError = false,
  }) : super(type: 'stop');

  factory StopStep.fromJson(Map<String, dynamic> j) => StopStep(
    id: j['id'],
    icon: "stop_circle",
    color: j['color'],
    label: j['label'],
    enabled: j['enabled'] ?? true,
    message: j['message'],
    throwError: j['throw_error'] ?? false,
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'label': label,
    'enabled': enabled,
    'message': message,
    'color': color,
    'throw_error': throwError,
  };

  @override
  dynamic getField(String name) => switch (name) {
    'message' => message,
    'throwError' => throwError,
    _ => super.getField(name),
  };

  @override
  void setField(String name, dynamic v) {
    switch (name) {
      case 'message':
        message = v?.toString();
      case 'throwError':
        throwError = v == true;
      default:
        super.setField(name, v);
    }
  }
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
  String id;
  String name;
  String description;
  String icon;
  bool enabled;
  Trigger trigger;
  List<Step> steps;
  DateTime createdAt;
  DateTime updatedAt;

  Shortcut({
    String? id,
    required this.name,
    this.description = '',
    this.icon = 'star',
    this.enabled = true,
    required this.trigger,
    List<Step>? steps,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? newId(),
       steps = List.of(steps ?? const []),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, Step> stepsById() => {for (final s in steps) s.id: s};

  /// First unused `sN` id. Scanning avoids collisions after deletes (a plain
  /// `steps.length` counter would reuse an id that a later step still holds).
  String _freshStepId() {
    final existing = {for (final s in steps) s.id};
    var i = 0;
    while (existing.contains('s$i')) {
      i++;
    }
    return 's$i';
  }

  /// Construct (but do not insert) a step from a palette def. `def.id` matches a
  /// control-flow step type ('if', 'loop', ...) or an action id; actions fall
  /// through to the default and carry their config in the generic `inputs` map.
  /// Scalar config for control steps is seeded from the def schema via
  /// `setField`.
  Step _buildStep({required ActionDef def, required String id}) {
    final seed = <String, dynamic>{
      for (final input in def.inputs) input.name: input.default_,
    };

    Step step;
    switch (def.id) {
      case 'if':
        step = IfStep(
          id: id,
          icon: def.icon,
          color: def.color,
          label: def.name,
          condition: '',
        );
      case 'loop':
        step = LoopStep(
          id: id,
          icon: def.icon,
          color: def.color,
          label: def.name,
          over: '',
          variable: 'item',
        );
      case 'repeat':
        step = RepeatStep(
          id: id,
          icon: def.icon,
          color: def.color,
          label: def.name,
          times: 1,
        );
      case 'wait':
        step = WaitStep(
          id: id,
          icon: def.icon,
          color: def.color,
          label: def.name,
          duration: 0,
        );
      case 'stop':
        step = StopStep(
          id: id,
          icon: def.icon,
          color: def.color,
          label: def.name,
        );
      case 'set_var':
        step = SetVarStep(
          id: id,
          icon: def.icon,
          color: def.color,
          label: def.name,
          varName: '',
        );
      default:
        return ActionStep(
          actionId: def.id,
          id: id,
          enabled: true,
          inputs: seed,
          label: def.name,
          icon: def.icon,
          color: def.color,
          description: def.description,
        );
    }

    // Seed scalar config fields from the schema defaults.
    for (final input in def.inputs) {
      if (input.default_ != null) step.setField(input.name, input.default_);
    }
    return step;
  }

  /// Append a step from a palette def. Every step lives in the flat `steps`
  /// list; a container's children are referenced by id. When [branch] is given
  /// (an If's `then`/`else` list, or a loop/repeat body), the new step's id is
  /// registered there so it renders and runs inside that container; otherwise
  /// it becomes a top-level step. Returns the created step.
  Step addStep({required ActionDef def, List<String>? branch}) {
    final step = _buildStep(def: def, id: _freshStepId());
    steps.add(step);
    branch?.add(step.id);
    return step;
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
  final String color;
  final List<String> platforms;

  ActionSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.icon,
    required this.color,
    required this.platforms,
  });
}
